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


/** �N���[�Y */
void MmcDrv_Close(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj)
{
	C_MMCDRV	*self;
	C_MEMFILE	*pFile;
	
	/* upper cast */
	self  = (C_MMCDRV *)pDrvObj;
	pFile = (C_MEMFILE *)pFileObj;

	SysMtx_Lock(self->hMtx);
	
	/* �N���[�Y���� */
	--self->iOpenCount;
	
	/* �f�B�X�N���v�^�폜 */
	FileObj_Delete((C_FILEOBJ *)pFile);	
	SysMem_Free(pFile);

	SysMtx_Unlock(self->hMtx);
}


/* end of file */
