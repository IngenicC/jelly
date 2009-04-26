/** 
 * Hyper Operating System  Application Framework
 *
 * @file  memfile.h
 * @brief %jp{memory file ���J�w�b�_�t�@�C��}%en{Memory File public header file}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __HOS__memfile_h__
#define __HOS__memfile_h__


#include "mmcdrv_local.h"


#ifdef __cplusplus
extern "C" {
#endif

HANDLE MemFile_Create(C_MMCDRV *pMmcDrv, int iMode);
void   MemFile_Delete(HANDLE hFile);

#ifdef __cplusplus
}
#endif


#endif	/*  __HOS__memfile_h__ */


/* end of file */
