/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{�������}�b�v�h�t�@�C���p�f�o�C�X�h���C�o}
 *
 * Copyright (C) 2006-2007 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __HOS__mmcdrv_h__
#define __HOS__mmcdrv_h__


#include "system/file/drvobj.h"


#ifdef __cplusplus
extern "C" {
#endif

HANDLE MmcDrv_Create(void *pMemAddr, FILE_POS MemSize, FILE_POS IniSize, int iAttr);	/**< ���� */
void   MmcDrv_Delete(HANDLE hDriver);													/**< �폜 */

#ifdef __cplusplus
}
#endif


#endif	/* __HOS__mmcdrv_h__ */


/* end of file */
