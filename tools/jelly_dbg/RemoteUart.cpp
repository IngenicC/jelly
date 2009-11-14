// ---------------------------------------------------------------------------
//  Jelly Debugger
//
//                                      Copyright (C) 2008 by Ryuji Fuchikami
// ---------------------------------------------------------------------------


#include "RemoteUart.h"


CRemoteUart::CRemoteUart(long lSpeed)
{
	m_hCom   = INVALID_HANDLE_VALUE;
	m_lSpeed = lSpeed;
}


CRemoteUart::~CRemoteUart()
{
	Close();
}


bool CRemoteUart::Open(const char* szName)
{
	DCB		dcb;

	/* COM�|�[�g�I�[�v�� */
	m_hCom = CreateFile(szName, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if ( m_hCom == INVALID_HANDLE_VALUE )
	{
		return false;
	}
	
	/* COM�ݒ� */
	memset(&dcb, 0, sizeof(dcb));
	dcb.DCBlength = sizeof(dcb);
	GetCommState(m_hCom, &dcb);
	dcb.BaudRate          = m_lSpeed;				/* �ʐM���x */
	dcb.fBinary           = TRUE;					/* �o�C�i�����[�h�̐ݒ� */
    dcb.fParity           = FALSE;					/* �p���e�B�̐ݒ� */
    dcb.fOutxCtsFlow      = FALSE;					/* CTS�o�̓t���[�R���g���[���̐ݒ� */
    dcb.fOutxDsrFlow      = FALSE;					/* DSR�o�̓t���[�R���g���[���̐ݒ� */
    dcb.fDtrControl       = DTR_CONTROL_DISABLE;	/* DTR�t���[�R���g���[���̎�� */
    dcb.fDsrSensitivity   = FALSE;					/* DSR�M�������̐ݒ� */
    dcb.fTXContinueOnXoff = FALSE;					/* XOFF���M��̏����̐ݒ� */
    dcb.fOutX             = FALSE;					/* XON/XOFF�o�̓t���[�R���g���[���̐ݒ� */
    dcb.fInX              = FALSE;					/* XON/XOFF���̓t���[�R���g���[���̐ݒ� */
    dcb.fErrorChar        = 0;						/* �p���e�B�G���[�̑�֕����̐ݒ� */
    dcb.fNull             = FALSE;                  /* NULL�o�C�g�̔j�� */
    dcb.fRtsControl       = RTS_CONTROL_DISABLE;	/* RTS�t���[�R���g���[���̐ݒ� */
    dcb.fAbortOnError     = FALSE;			        /* �G���[���̓��� */
    dcb.ByteSize          = 8;						/* 1�o�C�g�̃T�C�Y */
    dcb.Parity            = NOPARITY;				/* �p���e�B�̎�� */
    dcb.StopBits          = ONESTOPBIT;				/* �X�g�b�v�r�b�g�̎�� */
	if ( !SetCommState(m_hCom, &dcb) )
	{
		return false;
	}
	
	/* COM�^�C���A�E�g�ݒ� */	
	COMMTIMEOUTS cto;
	memset(&cto, 0, sizeof(cto));
	GetCommTimeouts(m_hCom, &cto);
	cto.ReadIntervalTimeout         = MAXDWORD;
	cto.ReadTotalTimeoutMultiplier  = 20;
	cto.ReadTotalTimeoutConstant    = 100;
	cto.WriteTotalTimeoutMultiplier = 10;
	cto.WriteTotalTimeoutConstant   = 1000;
	SetCommTimeouts(m_hCom, &cto);
	
	/* COM�o�b�t�@�ݒ� */
	SetupComm(m_hCom, 256 * 1024, 256 * 1024);
	
	return true;
}

// ����
void CRemoteUart::Close(void)
{
	if ( m_hCom != INVALID_HANDLE_VALUE )
	{
		CloseHandle(m_hCom);
	}
	m_hCom = INVALID_HANDLE_VALUE;
}

// ���M
int CRemoteUart::Send(const unsigned char *pbyData, int iSize)
{
	if ( m_hCom == INVALID_HANDLE_VALUE )
	{
		return 0;
	}

	DWORD	dwWriteSize;
	if ( WriteFile(m_hCom, pbyData, iSize, &dwWriteSize, NULL) == 0 )
	{
		return 0;
	}

	return (int)dwWriteSize;
}

// ��M
int CRemoteUart::Recv(unsigned char *pbyBuf, int iSize)
{
	if ( m_hCom == INVALID_HANDLE_VALUE )
	{
		return 0;
	}

	DWORD	dwReadSize;
	if ( ReadFile(m_hCom, pbyBuf, iSize, &dwReadSize, NULL) == 0 )
	{
		return 0;
	}

	return (int)dwReadSize;
}


