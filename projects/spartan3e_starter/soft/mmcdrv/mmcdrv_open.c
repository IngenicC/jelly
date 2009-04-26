/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv.h
 * @brief %jp{�������}�b�v�h�t�@�C���p�f�o�C�X�h���C�o}
 *
 * Copyright (C) 2006-2007 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "mmcdrv_local.h"
#include "system/sysapi/sysapi.h"
#include "memfile.h"


/** �I�[�v�� */
HANDLE MmcDrv_Open(C_DRVOBJ *pDrvObj, const char *pszPath, int iMode)
{
	C_MMCDRV	*self;
	HANDLE		hFile;
	
	/* upper cast */
	self = (C_MMCDRV *)pDrvObj;

	SysMtx_Lock(self->hMtx);
	
	/* create file descriptor */
	hFile = MemFile_Create(self, iMode);
	if ( hFile == HANDLE_NULL )
	{
		SysMtx_Unlock(self->hMtx);
		return HANDLE_NULL;
	}
	
	if ( iMode & FILE_OPEN_CREATE )
	{
		self->FileSize = 0;
	}
	
	/* �I�[�v������ */
	self->iOpenCount++;

	SysMtx_Unlock(self->hMtx);
	
	return hFile;
}


/* end of file */
