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


/** �폜 */
void MmcDrv_Delete(HANDLE hDriver)
{
	C_MMCDRV	*self;
	
	/* upper cast */
	self = (C_MMCDRV *)hDriver;

	/* �f�X�g���N�^�Ăяo�� */
	MmcDrv_Destructor(self);
	
	/* �������폜 */
	SysMem_Free(self);
}



/* end of file */
