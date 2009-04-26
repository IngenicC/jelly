/** 
 *  Hyper Operating System  Application Framework
 *
 * @file  mmcdrv_local.h
 * @brief %jp{�������}�b�v�h�t�@�C���p�f�o�C�X�h���C�o ���[�J���w�b�_�t�@�C��}
 *
 * Copyright (C) 2006-2007 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#ifndef __HOS__mmcdrv_local_h__
#define __HOS__mmcdrv_local_h__


#include "mmcdrv.h"
#include "system/file/drvobj_local.h"
#include "system/sysapi/sysapi.h"


/* �h���C�o���䕔 */
typedef struct c_mmcdrv
{
	C_DRVOBJ		DrvObj;			/* �f�o�C�X�h���C�o���p�� */

	int				iOpenCount;		/* �I�[�v���J�E���^ */
	FILE_SIZE		FileSize;

	SYSMTX_HANDLE	hMtx;			/* �r������p�~���[�e�b�N�X */
} C_MMCDRV;


#include "mmcfile_local.h"


#ifdef __cplusplus
extern "C" {
#endif

void      MmcDrv_Constructor(C_MMCDRV *self, const T_DRVOBJ_METHODS *pMethods, void *pMemAddr, FILE_POS MemSize, FILE_POS IniSize, int iAttr);	/** �R���X�g���N�^ */
void      MmcDrv_Destructor(C_MMCDRV *self);																									/** �f�X�g���N�^ */

HANDLE    MmcDrv_Open(C_DRVOBJ *pDrvObj, const char *pszPath, int iMode);
void      MmcDrv_Close(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj);
FILE_ERR  MmcDrv_IoControl(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, int iFunc, void *pInBuf, FILE_SIZE InSize, const void *pOutBuf, FILE_SIZE OutSize);
FILE_POS  MmcDrv_Seek(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, FILE_POS Offset, int iOrign);
FILE_SIZE MmcDrv_Read(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, void *pBuf, FILE_SIZE Size);
FILE_SIZE MmcDrv_Write(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj, const void *pData, FILE_SIZE Size);
FILE_ERR  MmcDrv_Flush(C_DRVOBJ *pDrvObj, C_FILEOBJ *pFileObj);
FILE_ERR  MmcDrv_GetInformation(C_DRVOBJ *pDrvObj, char *pszInformation, int iLen);

int       MmcDrv_CardInit(C_MMCDRV *self);
FILE_SIZE MmcDrv_BlockRead(C_MMCDRV *self, unsigned long uwAddr, void *pBuf);
FILE_SIZE MmcDrv_BlockWrite(C_MMCDRV *self, unsigned long uwAddr, const void *pBuf);

#ifdef __cplusplus
}
#endif


#endif	/* __HOS__mmcdrv_local_h__ */


/* end of file */
