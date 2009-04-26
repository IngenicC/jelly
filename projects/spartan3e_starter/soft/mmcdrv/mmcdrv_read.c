/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{�������}�b�v�h�t�@�C���p�f�o�C�X�h���C�o}
 *
 * Copyright (C) 2006-2007 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include <string.h>
#include "mmcdrv_local.h"



FILE_SIZE MmcDrv_Read(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, void *pBuf, FILE_SIZE Size)
{
	C_MMCDRV	*self;
	C_MMCFILE	*pFile;
	
	/* upper cast */
	self  = (C_MMCDRV *)pDrvObj;
	pFile = (C_MMCFILE *)pFileObj;
	
	SysMtx_Lock(self->hMtx);
	
	
	SysMtx_Unlock(self->hMtx);
	
	return Size;
}


/* end of file */
