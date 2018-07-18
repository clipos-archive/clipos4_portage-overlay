#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <winpr/crt.h>
#include <winpr/cmdline.h>

#include <freerdp/addin.h>

#include <winpr/stream.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <errno.h>

#include <winpr/thread.h>

#include "dvcsocket_main.h"

#define DEFAULT_SOCKET_PATH "/var/run/p11proxy/socket"

typedef struct _DVCSOCKET_LISTENER_CALLBACK DVCSOCKET_LISTENER_CALLBACK;
struct _DVCSOCKET_LISTENER_CALLBACK
{
	IWTSListenerCallback iface;

	IWTSPlugin* plugin;
	IWTSVirtualChannelManager* channel_mgr;
};

typedef struct _DVCSOCKET_CHANNEL_CALLBACK DVCSOCKET_CHANNEL_CALLBACK;
struct _DVCSOCKET_CHANNEL_CALLBACK
{
	IWTSVirtualChannelCallback iface;

	IWTSPlugin* plugin;
	IWTSVirtualChannelManager* channel_mgr;
	IWTSVirtualChannel* channel;

    /* Specific plugin data */
    int local_socket_fd;			/* File descriptor to the opened socket */
    HANDLE writeThread;				/* thread to send data back in channel */
    HANDLE sockreadThread;			/* thread to read on socket */
    HANDLE sockwriteThread;			/* thread to write on socket */
    wQueue *input_stream_list;		/* Queue to store received data */
    wQueue *output_stream_list;		/* Queue to store data to send back */
    HANDLE socket_mutex;			/* mutex to synchronize socket access */
    int thread_count;				/* counter decremented each time a thread has terminated */
    HANDLE stopAllThreadsEvent;		/* Event to terminate thread */
    HANDLE writeThreadEvent;		/* Event signaling writeThread terminaison */
    HANDLE sockreadThreadEvent;		/* Event signaling sockreadThread terminaison */
    HANDLE sockwriteThreadEvent;	/* Event signaling sockwriteThread terminaison */
};

typedef struct _DVCSOCKET_PLUGIN DVCSOCKET_PLUGIN;
struct _DVCSOCKET_PLUGIN
{
	IWTSPlugin iface;

	DVCSOCKET_LISTENER_CALLBACK* listener_callback;
};

/* Open a UNIX socket to DEFAULT_SOCKET_PATH, non blocking mode */
static int open_socket(){
    int ret;
    int len;
    int fd;
    /* path to socket */
    char *socket_path = DEFAULT_SOCKET_PATH;

    struct sockaddr_un *serv_addr;

    serv_addr = malloc(sizeof(struct sockaddr_un));
    if(serv_addr == NULL){
        fprintf(stderr, "Error: Could not allocate memory\n");
        exit(-1);
    }
    serv_addr->sun_family = AF_UNIX;
    /* try to find user-defined path to socket */
    strncpy(serv_addr->sun_path, socket_path,
            (sizeof(serv_addr->sun_path) - 1));
   
    fd = socket(AF_UNIX, SOCK_STREAM, 0);
    len = strlen (serv_addr->sun_path) + sizeof (serv_addr->sun_family) + 1;
    ret = connect(fd, (struct sockaddr *) serv_addr, len);
    if (ret != 0){
        fprintf(stderr, "Error: Could not connect to socket\n");
        exit(-1);
    }
#ifndef FreeBSD
    /* We have to free the pointer, FreeBSD does it in its libc ... */
    free(serv_addr);
#endif
    /* Get current modes */
    ret = fcntl (fd, F_GETFL, 0);
    if(ret == -1){
        fprintf(stderr, "Error: Could not call fcntl F_GETFL on socket\n");
        exit(-1);
    }
    /* Set the socket to non blocking mode */
    ret = fcntl (fd, F_SETFL, ret | O_NONBLOCK);
    if(ret == -1){
        fprintf(stderr, "Error: Could not set socket to O_NONBLOCK\n");
        exit(-1);
    }
    return fd;
}

/* Method called to process received data, enqueue data for other thread to process */
static int dvcsocket_on_data_received(IWTSVirtualChannelCallback* pChannelCallback, UINT32 cbSize, BYTE* pBuffer)
{
	int error = 0;
	DVCSOCKET_CHANNEL_CALLBACK* callback = (DVCSOCKET_CHANNEL_CALLBACK*) pChannelCallback;
	DVCSOCKET_PLUGIN *dvcsocket;
    wStream* data_in;

	/* Do the stuff here */

    DEBUG_DVC("dvcsocket_on_data_received:");
	if(callback == NULL){
    	fprintf(stderr, "dvcsocket_on_data_received: callback is nil\n");
		return -1;
	}
	dvcsocket = (DVCSOCKET_PLUGIN*)callback->plugin;

    DEBUG_DVC("dvcsocket_on_data_received: got bytes %d", cbSize);

    if (cbSize > 0)
    {
#ifdef WITH_DEBUG_DVC
		winpr_CArrayDump(pBuffer, cbSize, 80);
#endif
		/* Create a wStream from input buffer */
        data_in = Stream_New(NULL, cbSize);
        Stream_Write(data_in, pBuffer, cbSize);
        Stream_Rewind(data_in, cbSize);

        DEBUG_DVC("dvcsocket_on_data_received: append to Queue bytes %d", cbSize);

        /* Append received data to Queue, it will be freed once written to the socket */
        Queue_Enqueue(callback->input_stream_list, data_in);
    }
	return error;
}

/* Method used to cleanup on channel close */
static int dvcsocket_on_close(IWTSVirtualChannelCallback* pChannelCallback)
{
	DVCSOCKET_CHANNEL_CALLBACK* callback = (DVCSOCKET_CHANNEL_CALLBACK*) pChannelCallback;
	DWORD dwWaitEvent;
	HANDLE waitObj[3];

	/* Waiting to flush */
	while(Queue_Count(callback->input_stream_list) != 0){
		USleep(2000);
	}

	while(Queue_Count(callback->output_stream_list) != 0){
		USleep(2000);
	}

    DEBUG_DVC("dvcsocket_on_close: asking worker threads to terminate");
	waitObj[0] = callback->writeThreadEvent;
	waitObj[1] = callback->sockreadThreadEvent;
	waitObj[2] = callback->sockwriteThreadEvent;

	SetEvent(callback->stopAllThreadsEvent);
	while(1){
		if(callback->thread_count == 0){
			DEBUG_DVC("dvcsocket_on_close: All good %lu", sizeof(*callback));
			break;
		}
		/* WinPR does not "yet" support waiting for all events to occur, we need to use a counter */
        dwWaitEvent = WaitForMultipleObjects(3, waitObj, FALSE, INFINITE);
		switch(dwWaitEvent){
			case WAIT_OBJECT_0:{
				DEBUG_DVC("dvcsocket_on_close: Event writeThreadEvent");
				callback->thread_count = callback->thread_count - 1;
				ResetEvent(callback->writeThreadEvent);
				if(callback->thread_count == 0){
					break;
				}
			}
			case WAIT_OBJECT_0 +1:{
				DEBUG_DVC("dvcsocket_on_close: Event sockreadThreadEvent");
				ResetEvent(callback->sockreadThreadEvent);
				callback->thread_count = callback->thread_count - 1;
				if(callback->thread_count == 0){
					break;
				}

			}
			case WAIT_OBJECT_0 +2:{
				DEBUG_DVC("dvcsocket_on_close: Event sockwriteThreadEvent");
				ResetEvent(callback->sockwriteThreadEvent);
				callback->thread_count = callback->thread_count - 1;
				DEBUG_DVC("dvcsocket_on_close: waiting for %d count to be 0", callback->thread_count);
				if(callback->thread_count == 0){
					break;
				}
			}
		}
	}

	DEBUG_DVC("dvcsocket_on_close: All worker threads returned, closing handles");
	CloseHandle(callback->socket_mutex);
	CloseHandle(callback->stopAllThreadsEvent);

    CloseHandle(callback->writeThread);
    CloseHandle(callback->sockwriteThread);
    CloseHandle(callback->sockreadThread);

    CloseHandle(callback->writeThreadEvent);
    CloseHandle(callback->sockwriteThreadEvent);
    CloseHandle(callback->sockreadThreadEvent);


	Queue_Free(callback->output_stream_list);
	Queue_Free(callback->input_stream_list);

	if(close(callback->local_socket_fd)){
		fprintf(stderr, "dvcsocket_on_close: Error closing socket\n");
	}

	free(callback);
	callback = NULL;

	return 0;
}

/* Method used to send back some data from Queue */
static void dvcsocket_process_send_data_back(DVCSOCKET_CHANNEL_CALLBACK* callback){
	int error;
	HANDLE waitObj[2];
	DWORD dwWaitEvent;

    if (!callback)
    {
        fprintf(stderr, "sample_process_send_data_back: callback is nil\n");
        return;
    }

	waitObj[0] = Queue_Event(callback->output_stream_list);
	waitObj[1] = callback->stopAllThreadsEvent;
    while (1)
    {
        dwWaitEvent = WaitForMultipleObjects(2, waitObj, FALSE, INFINITE);
        switch(dwWaitEvent){
            case WAIT_OBJECT_0:{//dataOutEvent signaled
                DEBUG_DVC("sample_process_send_data_back: should send data back");
                wStream *stream_to_send = (wStream*) Queue_Dequeue(callback->output_stream_list);

                if (stream_to_send){
                    DEBUG_DVC("sample_process_send_data_back: sending back some data: len %zu", Stream_Length(stream_to_send));
#ifdef WITH_DEBUG_DVC
					winpr_CArrayDump(Stream_Buffer(stream_to_send), Stream_Length(stream_to_send), 80);
#endif
					error = callback->channel->Write(callback->channel, Stream_Length(stream_to_send), Stream_Buffer(stream_to_send), NULL);
					if(error){
						//Oups ...
                    	fprintf(stderr, "sample_process_send_data_back: Error sending bytes\n");
						return;
					}
                    DEBUG_DVC("sample_process_send_data_back: DONE sending bytes");
					Stream_Free(stream_to_send, TRUE);
                    }
                break;
                }
            case (WAIT_OBJECT_0 + 1 ) :{//stopAllThreadsEvent event
                //Indicate will proceed
                DEBUG_DVC("sample_process_send_data_back: shutdown request, EXITING");
                DEBUG_DVC("sample_process_send_data_back: shutdown request, callback is %p", callback);
				SetEvent(callback->writeThreadEvent);
                ExitThread(0);
            }
            default:
                fprintf(stderr, "sample_process_send_data_back: Error WaitForMultipleObjects\n");
                return;
        }
    }
    return;
}

/* Method used to fetch data from Queue and write it to local socket */
static void dvcsocket_process_write_to_socket(DVCSOCKET_CHANNEL_CALLBACK* callback){
    DVCSOCKET_PLUGIN* sample = (DVCSOCKET_PLUGIN*) callback->plugin;
    wStream *stream_to_send = NULL;
    int bytes_sent =0;
    DWORD dwWaitEvent, dwWaitWriteMutex;
	HANDLE waitObj[2];

    if (!sample)
    {
        fprintf(stderr, "sample_process_write_to_socket: sample is nil\n");
        return;
    }
	waitObj[0] = Queue_Event(callback->input_stream_list);
	waitObj[1] = callback->stopAllThreadsEvent;
    // Fetch data from Qeue and write it to socket
    while (1)
    {
        dwWaitEvent = WaitForMultipleObjects(2, waitObj, FALSE, INFINITE);
        switch(dwWaitEvent){
            case WAIT_OBJECT_0:{ // dataInEvent
                // Check if previous data was completely written
                if(stream_to_send == NULL && bytes_sent == 0){
                    DEBUG_DVC("sample_process_write_to_socket: dequeing some data");
                    stream_to_send = (wStream*) Queue_Dequeue(callback->input_stream_list);
                    if (stream_to_send){
                        // Try to write it to socket, if not completely written, keep remaining
                        DEBUG_DVC("sample_process_write_to_socket: found %zu bytes to send!\n", Stream_Length(stream_to_send));
                        //TAKE MUTEX
                        dwWaitWriteMutex = WaitForSingleObject(callback->socket_mutex, INFINITE);
                        switch(dwWaitWriteMutex){
                            case WAIT_OBJECT_0:{
                                bytes_sent = write(callback->local_socket_fd, Stream_Buffer(stream_to_send), Stream_Length(stream_to_send));
                                //RELEASE MUTEX
                                if (! ReleaseMutex(callback->socket_mutex)){
                                    fprintf(stderr, "sample_process_write_to_socket: Error Releasing socket_mutex\n");
                                    return;
                                }
                                break;
                            }
                            default:
                                fprintf(stderr, "sample_process_write_to_socket: Error WaitForSingleObject on socket_mutex\n");
                                return;
                        }
                        if(bytes_sent < 0){
                            if (errno != EAGAIN){
                            fprintf(stderr, "sample_process_write_to_socket: ERROR writing to socket!\n");
                            return;
                            }
                        }
                        else
                            DEBUG_DVC("sample_process_write_to_socket: wrote %d bytes", bytes_sent);
                        if(bytes_sent == Stream_Length(stream_to_send)){
                        //Data was completely written, cleanup
                            DEBUG_DVC("sample_process_write_to_socket: All data written to socket!");
                            Stream_Free(stream_to_send, TRUE);
                            stream_to_send = NULL;
                            bytes_sent = 0;
                        }
                        else{
                            //Deplace stream pointer, to reflect how much we read
                            Stream_Seek(stream_to_send, bytes_sent);
                        }
                    }
                }
                else{
                    //Data was not completely written
                    DEBUG_DVC("sample_process_write_to_socket: %lu bytes remaining, doing another write", Stream_GetRemainingLength(stream_to_send));
                    //Take socket MUTEX
                    dwWaitWriteMutex = WaitForSingleObject(callback->socket_mutex, INFINITE);
                    switch(dwWaitWriteMutex){
                        case WAIT_OBJECT_0:{
                            bytes_sent = write(callback->local_socket_fd, Stream_Pointer(stream_to_send), Stream_GetRemainingLength(stream_to_send));
                            //Release socket MUTEX
                            if (! ReleaseMutex(callback->socket_mutex)){
                                fprintf(stderr, "sample_process_write_to_socket: Error Releasing socket_mutex\n");
                                return;
                            }
                            break;
                        }
                        default:
                            fprintf(stderr, "sample_process_write_to_socket: Error WaitForSingleObject on socket_mutex\n");
                            return;
                    }
                    if(bytes_sent < 0){
                        if (errno != EAGAIN){
                            fprintf(stderr, "sample_process_write_to_socket: ERROR writing to socket!\n");
                            return;
                        }
                    }
                    else
                        DEBUG_DVC("sample_process_write_to_socket: wrote %d bytes", bytes_sent);
                    if(bytes_sent == Stream_GetRemainingLength(stream_to_send)){
                    	/* Data was completely written, cleanup */
                        Stream_Free(stream_to_send, TRUE);
                        stream_to_send = NULL;
                        bytes_sent = 0;
                    }
                    else{
                        /* Deplace stream pointer, to reflect how much we read */
                        Stream_Seek(stream_to_send, bytes_sent);
                    }
                }
                break;
                }
			case (WAIT_OBJECT_0 + 1 ) :{//stopAllThreadsEvent event
                //Indicate will proceed
                DEBUG_DVC("sample_process_write_to_socket:: shutdown request, EXITING");
				SetEvent(callback->sockwriteThreadEvent);
                ExitThread(0);
			}
            default:
                fprintf(stderr, "sample_process_write_to_socket: Error WaitForSingleObject on dataInEvent\n");
                return;
        }
    }
    return;
}

/* Method used to read data from socket and insert it in Queue */
static void dvcsocket_process_read_from_socket(DVCSOCKET_CHANNEL_CALLBACK* callback){
    wStream *tmp = NULL;
    wStream *stream_to_send = NULL;
    int bytes_read = 0;
    BYTE buff[2048] = {0};
    DWORD dwWaitReadMutex;


    if (!callback)
    {
        fprintf(stderr, "sample_process_read_from_socket: sample is nil\n");
        return;
    }
    // Read data from socket and insert it in Queue
    while (1)
    {
        if(WaitForSingleObject(callback->stopAllThreadsEvent, 0) == WAIT_OBJECT_0){
            //Indicate will proceed
            DEBUG_DVC("sample_process_read_from_socket: shutdown request, EXITING");
            DEBUG_DVC("sample_process_read_from_socket: shutdown callback is %p", callback);
			SetEvent(callback->sockreadThreadEvent);
            ExitThread(0);
        }

        //Take socket MUTEX
        dwWaitReadMutex = WaitForSingleObject(callback->socket_mutex, INFINITE);
        switch(dwWaitReadMutex){
            case WAIT_OBJECT_0:{
                bytes_read = read(callback->local_socket_fd, buff, 2048);
                //Release socket MUTEX
                if (! ReleaseMutex(callback->socket_mutex)){
                    fprintf(stderr, "sample_process_read_from_socket: Error Releasing socket_mutex\n");
                    return;
                }
                break;
            }
            default:
                fprintf(stderr, "sample_process_read_from_socket: Error WaitForSingleObject on socket_mutex\n");
                return;
        }
        if(bytes_read < 0){
            if (errno != EAGAIN){
                fprintf(stderr, "sample_process_read_from_socket: ERROR reading from socket!\n");
                return;
            }
        }
        else{
            DEBUG_DVC("sample_process_read_from_socket: read %d bytes", bytes_read);
            //Create tmp stream from to avoid "buff" being from when sent
            tmp = Stream_New(buff, bytes_read);
            stream_to_send = Stream_New(NULL, bytes_read);
            Stream_Copy(stream_to_send, tmp, bytes_read);
            //Free tmp stream but do not free buffer
            Stream_Free(tmp, FALSE);
            Queue_Enqueue(callback->output_stream_list, stream_to_send);
            bytes_read = 0;
            memset(buff, 0, 2048);
        }
    }
    return;
}

/* On new channel, instanciate structure, open new socket and spawn 3 new "worker" threads */
static int dvcsocket_on_new_channel_connection(IWTSListenerCallback* pListenerCallback,
	IWTSVirtualChannel* pChannel, BYTE* Data, int* pbAccept,
	IWTSVirtualChannelCallback** ppCallback)
{
	DVCSOCKET_CHANNEL_CALLBACK* callback;
	DVCSOCKET_LISTENER_CALLBACK* listener_callback = (DVCSOCKET_LISTENER_CALLBACK*) pListenerCallback;

	/* Init here code related to channel ID */

	callback = (DVCSOCKET_CHANNEL_CALLBACK*) malloc(sizeof(DVCSOCKET_CHANNEL_CALLBACK));
	ZeroMemory(callback, sizeof(DVCSOCKET_CHANNEL_CALLBACK));

	callback->iface.OnDataReceived = dvcsocket_on_data_received;
	callback->iface.OnClose = dvcsocket_on_close;
	callback->plugin = listener_callback->plugin;
	callback->channel_mgr = listener_callback->channel_mgr;
	callback->channel = pChannel;

    callback->local_socket_fd = open_socket();
    callback->thread_count = 3;

    callback->socket_mutex = CreateMutex(NULL, FALSE, NULL);
    callback->output_stream_list = Queue_New(TRUE, -1, -1);
    callback->input_stream_list = Queue_New(TRUE, -1, -1);
    callback->stopAllThreadsEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    callback->writeThreadEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    callback->sockwriteThreadEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    callback->sockreadThreadEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

    if (!callback->writeThread)
    {
        DEBUG_DVC("callback_process_initialize: creating writeThread");
        callback->writeThread = CreateThread(NULL, 0,
            (LPTHREAD_START_ROUTINE) dvcsocket_process_send_data_back,
            (void*) callback, 0, NULL);
    }
    if (!callback->sockreadThread)
    {
        DEBUG_DVC("callback_process_initialize: creating sockreadThread");
        callback->sockreadThread = CreateThread(NULL, 0,
            (LPTHREAD_START_ROUTINE) dvcsocket_process_read_from_socket,
            (void*) callback, 0, NULL);
    }
    if (!callback->sockwriteThread)
    {
        DEBUG_DVC("callback_process_initialize: creating sockwriteThread");
        callback->sockwriteThread = CreateThread(NULL, 0,
            (LPTHREAD_START_ROUTINE) dvcsocket_process_write_to_socket,
            (void*) callback, 0, NULL);
    }

	*ppCallback = (IWTSVirtualChannelCallback*) callback;

	return 0;
}


static int dvcsocket_plugin_initialize(IWTSPlugin* pPlugin, IWTSVirtualChannelManager* pChannelMgr)
{
	DVCSOCKET_PLUGIN* dvcsocket = (DVCSOCKET_PLUGIN*) pPlugin;

	dvcsocket->listener_callback = (DVCSOCKET_LISTENER_CALLBACK*) malloc(sizeof(DVCSOCKET_LISTENER_CALLBACK));
	ZeroMemory(dvcsocket->listener_callback, sizeof(DVCSOCKET_LISTENER_CALLBACK));

	dvcsocket->listener_callback->iface.OnNewChannelConnection = dvcsocket_on_new_channel_connection;
	dvcsocket->listener_callback->plugin = pPlugin;
	dvcsocket->listener_callback->channel_mgr = pChannelMgr;


	return pChannelMgr->CreateListener(pChannelMgr, "DVCSOCKET", 0,
		(IWTSListenerCallback*) dvcsocket->listener_callback, NULL);
}

static int dvcsocket_plugin_terminated(IWTSPlugin* pPlugin)
{
	DVCSOCKET_PLUGIN* dvcsocket = (DVCSOCKET_PLUGIN*) pPlugin;

	free(dvcsocket);

	return 0;
}

#ifdef STATIC_CHANNELS
#define DVCPluginEntry		dvcsocket_DVCPluginEntry
#endif

int DVCPluginEntry(IDRDYNVC_ENTRY_POINTS* pEntryPoints)
{
	int error = 0;
	DVCSOCKET_PLUGIN* dvcsocket;

	dvcsocket = (DVCSOCKET_PLUGIN*) pEntryPoints->GetPlugin(pEntryPoints, "dvcsocket");

	if (dvcsocket == NULL)
	{
		dvcsocket = (DVCSOCKET_PLUGIN*) malloc(sizeof(DVCSOCKET_PLUGIN));
		ZeroMemory(dvcsocket, sizeof(DVCSOCKET_PLUGIN));

		dvcsocket->iface.Initialize = dvcsocket_plugin_initialize;
		dvcsocket->iface.Connected = NULL;
		dvcsocket->iface.Disconnected = NULL;
		dvcsocket->iface.Terminated = dvcsocket_plugin_terminated;

		error = pEntryPoints->RegisterPlugin(pEntryPoints, "dvcsocket", (IWTSPlugin*) dvcsocket);
	}

	return error;
}
