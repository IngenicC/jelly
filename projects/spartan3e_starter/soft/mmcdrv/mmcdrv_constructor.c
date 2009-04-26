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


/* ���z�֐��e�[�u�� */
static const T_DRVOBJ_METHODS MmcDrv_Methods = 
	{
		{ MmcDrv_Delete },
		MmcDrv_Open,
		MmcDrv_Close,
		MmcDrv_IoControl,
		MmcDrv_Seek,
		MmcDrv_Read,
		MmcDrv_Write,
		MmcDrv_Flush,
		MmcDrv_GetInformation,
	};


/** �R���X�g���N�^ */
void MmcDrv_Constructor(C_MMCDRV *self, const T_DRVOBJ_METHODS *pMethods, void *pMemAddr, FILE_POS MemSize, FILE_POS IniSize, int iAttr)
{
	if ( pMethods == NULL )
	{
		pMethods = &MmcDrv_Methods;
	}
	
	/* �e�N���X�R���X�g���N�^�Ăяo�� */
	DrvObj_Constructor(&self->DrvObj, pMethods);
	
	/* �����o�ϐ������� */
	self->iOpenCount = 0;
	self->pubMemAddr = pMemAddr;	/* �������̐擪�A�h���X */
	self->MemSize    = MemSize;		/* �������T�C�Y */
	self->FileSize   = IniSize;		/* �t�@�C���Ƃ��ẴT�C�Y */
	self->iAttr      = iAttr;		/* ���� */
	
	/* �~���[�e�b�N�X���� */
	self->hMtx = SysMtx_Create(SYSMTX_ATTR_NORMAL);
}


/* end of file */
