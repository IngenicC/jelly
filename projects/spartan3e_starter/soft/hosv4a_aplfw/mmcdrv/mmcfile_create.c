/** 
 * Hyper Operating System  Application Framework
 *
 * @file  mmcfile.h
 * @brief %jp{memory file ���J�w�b�_�t�@�C��}%en{Memory File public header file}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "mmcfile_local.h"


static const T_FILEOBJ_METHODS MmcFile_FileObjMethods =
	{
		{File_Close},	/* �f�X�g���N�^ */
	};


HANDLE MmcFile_Create(C_MMCDRV *pMemVol, int iMode)
{
	C_MMCFILE *self;

	/* create file descriptor */
	if ( (self = (C_MMCFILE *)SysMem_Alloc(sizeof(C_MMCFILE))) == NULL )
	{
		return HANDLE_NULL;
	}
	
	/* �R���X�g���N�^�Ăяo�� */
	MmcFile_Constructor(self, &MmcFile_FileObjMethods, pMemVol, iMode);
	
	return (HANDLE)self;
}


/* end of file */
