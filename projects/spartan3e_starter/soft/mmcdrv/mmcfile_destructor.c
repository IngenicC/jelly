/** 
 * Hyper Operating System  Application Framework
 *
 * @file  memfile_destructor.c
 * @brief %jp{memory file �f�X�g���N�^}%en{Memory File  destructor}
 *
 * Copyright (C) 2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "memfile_local.h"


void  MemFile_Destructor(C_MEMFILE *self)
{
	/* �e�N���X�f�X�g���N�^ */		
	FileObj_Destructor(&self->FileObj);
}


/* end of file */
