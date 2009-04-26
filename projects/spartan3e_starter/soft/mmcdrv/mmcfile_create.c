/** 
 * Hyper Operating System  Application Framework
 *
 * @file  memfile.h
 * @brief %jp{memory file ���J�w�b�_�t�@�C��}%en{Memory File public header file}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "memfile_local.h"


static const T_FILEOBJ_METHODS MemFile_FileObjMethods =
	{
		{File_Close},	/* �f�X�g���N�^ */
	};


HANDLE MemFile_Create(C_MMCDRV *pMemVol, int iMode)
{
	C_MEMFILE *self;

	/* create file descriptor */
	if ( (self = (C_MEMFILE *)SysMem_Alloc(sizeof(C_MEMFILE))) == NULL )
	{
		return HANDLE_NULL;
	}
	
	/* �R���X�g���N�^�Ăяo�� */
	MemFile_Constructor(self, &MemFile_FileObjMethods, pMemVol, iMode);
	
	return (HANDLE)self;
}


/* end of file */
