/** 
 * Hyper Operating System  Application Framework
 *
 * @file  memfile.h
 * @brief %jp{memory file ���[�J���w�b�_�t�@�C��}%en{Memory File private header file}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __HOS__memfile_local_h__
#define __HOS__memfile_local_h__


#include "memfile.h"
#include "system/file/fileobj_local.h"
#include "system/sysapi/sysapi.h"


/* �t�@�C���f�B�X�N���v�^ */
typedef struct c_memfile
{
	C_FILEOBJ	FileObj;			/* �p�� */

	FILE_POS	FilePos;
} C_MEMFILE;


#ifdef __cplusplus
extern "C" {
#endif

void  MemFile_Constructor(C_MEMFILE *self, const T_FILEOBJ_METHODS *pMethods, C_MMCDRV *pMmcDrv, int iMode);
void  MemFile_Destructor(C_MEMFILE *self);

#ifdef __cplusplus
}
#endif



#endif	/*  __HOS__memfile_local_h__ */


/* end of file */
