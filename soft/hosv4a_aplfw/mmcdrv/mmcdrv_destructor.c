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


/** �f�X�g���N�^ */
void MmcDrv_Destructor(C_MMCDRV *self)
{
	/* �I�u�W�F�N�g�폜 */
	SysMtx_Delete(self->hMtx);
	
	/* �e�N���X�f�X�g���N�^ */
	DrvObj_Destructor(&self->DrvObj);
}


/* end of file */
