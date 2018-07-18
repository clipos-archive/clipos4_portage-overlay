/**
 * FreeRDP: A Remote Desktop Protocol Implementation
 * Echo Virtual Channel Extension
 *
 * Copyright 2013 Christian Hofstaedtler
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __DVCSAMPLE_MAIN_H
#define __DVCSAMPLE_MAIN_H

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <freerdp/dvc.h>
#include <freerdp/types.h>
#include <freerdp/addin.h>

/* from now remove include/freerdp/utils/debug.h file */
#define DEBUG_PRINT(level, file, fkt, line, dbg_str, fmt, ...) \
	do { \
		wLog *log = WLog_Get("com.freerdp.legacy"); \
		wLogMessage msg; \
		\
		msg.Type = WLOG_MESSAGE_TEXT; \
		msg.Level = level; \
		msg.FormatString = fmt; \
		msg.LineNumber = line; \
		msg.FileName = file; \
		msg.FunctionName = fkt; \
		WLog_PrintMessage(log, &msg, ##__VA_ARGS__); \
	} while (0 )

#define DEBUG_CLASS(_dbg_class, fmt, ...) DEBUG_PRINT(WLOG_ERROR, __FILE__, \
		__FUNCTION__, 	__LINE__, #_dbg_class, fmt, ## __VA_ARGS__)

#ifdef WITH_DEBUG_DVC
#define DEBUG_DVC(fmt, ...) DEBUG_CLASS(DVC, fmt, ## __VA_ARGS__)
#else
#define DEBUG_DVC(fmt, ...) do { } while (0)
#endif

#endif /* __DVCSAMPLE_MAIN_H */

