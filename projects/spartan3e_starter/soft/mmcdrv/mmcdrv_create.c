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




/** ���� */
HANDLE MmcDrv_Create(void *pMemAddr, FILE_POS MemSize, FILE_POS IniSize, int iAttr)
{
	C_MMCDRV *self;
	
	/* �������m�� */
	if ( (self = (C_MMCDRV *)SysMem_Alloc(sizeof(C_MMCDRV))) == NULL )
	{
		return HANDLE_NULL;
	}
	
	/* �R���X�g���N�^�Ăяo�� */
	MmcDrv_Constructor(self, NULL, pMemAddr, MemSize, IniSize, iAttr);
	
	return (HANDLE)self;
}


/* end of file */
