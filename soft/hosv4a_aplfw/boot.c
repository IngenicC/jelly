/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  sample.c
 * @brief %jp{�T���v���v���O����}%en{Sample program}
 *
 * Copyright (C) 1998-2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "kernel.h"
#include "kernel_id.h"
#include "system/system/system.h"
#include "system/sysapi/sysapi.h"
#include "system/file/console.h"
#include "system/process/process.h"
#include "system/command/command.h"
#include "driver/serial/jelly/jellyuartdrv.h"
#include "driver/console/vt100/vt100drv.h"
#include "driver/volume/fat/fatvol.h"
#include "application/syscmd/shell/shell.h"
#include "application/syscmd/commandlist/commandlist.h"
#include "application/syscmd/processlist/processlist.h"
#include "application/filecmd/filelist/filelist.h"
#include "application/filecmd/filecopy/filecopy.h"
#include "application/filecmd/filedump/filedump.h"
#include "application/filecmd/filecat/filecat.h"
#include "application/fatcmd/fatmount/fatmount.h"
#include "application/utility/timecmd/timecmd.h"
#include "application/utility/memdump/memdump.h"
#include "application/utility/memwrite/memwrite.h"
#include "application/utility/memtest/memtest.h"
#include "application/utility/keytest/keytest.h"
#include "application/example/hello/hello.h"
#include "boot.h"
#include "ostimer.h"
#include "mmcdrv/mmcdrv.h"


#if 0

long	g_SystemHeap[128 * 1024 / sizeof(long)];
#define SYSTEM_HEAP_ADDR	((void *)g_SystemHeap)
#define SYSTEM_HEAP_SIZE	sizeof(g_SystemHeap)

#else

#define SYSTEM_HEAP_ADDR	((void *)0x01300000)
#define SYSTEM_HEAP_SIZE	0x00100000

#endif


extern SYSTIM_CPUTIME		SysTim_TimeCounter;		/* �f�t�H���g�̃^�C�}�J�E���^ */



#define GPIOA_DIR		((volatile unsigned long *)0xf3000000)
#define GPIOA_INPUT 	((volatile unsigned long *)0xf3000004)
#define GPIOA_OUPUT 	((volatile unsigned long *)0xf3000008)

#define MMC_CS			0x01
#define MMC_DI			0x02
#define MMC_CLK			0x04
#define MMC_DO			0x08


unsigned char send_data(unsigned char ubData)
{
	unsigned char	ubRead = 0;
	unsigned long	c;
	int				i;
	
	c = (*GPIOA_OUPUT & ~(MMC_DI | MMC_CLK));
	
	for ( i = 0; i < 8; i++ )
	{
		ubRead <<= 1;
		if ( ubData & 0x80 )
		{
			*GPIOA_OUPUT = c | MMC_DI;
			ubRead |= (*GPIOA_INPUT & MMC_DO) ? 1 : 0;
			*GPIOA_OUPUT = c | MMC_DI | MMC_CLK;
		}
		else
		{
			*GPIOA_OUPUT = c;
			ubRead |= (*GPIOA_INPUT & MMC_DO) ? 1 : 0;
			*GPIOA_OUPUT = c | MMC_CLK;
		}
		ubData <<= 1;
	}
	
	return ubRead;
}


int test_main(int argc, char *argv[])
{
	int i;
	unsigned char c;
	
	*GPIOA_DIR   = 0x07;
	*GPIOA_OUPUT = 0x07;
	
	/* ������ */
	for ( i = 0; i < 80; i++ )
	{
		*GPIOA_OUPUT &= ~MMC_CLK;
		*GPIOA_OUPUT |=  MMC_CLK;
	}
	
	*GPIOA_OUPUT &= ~MMC_CS;
	
	send_data(0x40);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x95);
	send_data(0xff);
	c = send_data(0xff);
	StdIo_PrintFormat("%02x\n", (int)c);
	send_data(0xff);
	
	
	send_data(0x41);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0xf9);
	send_data(0xff);
	c = send_data(0xff);
	StdIo_PrintFormat("%02x\n", (int)c);
	send_data(0xff);
	
	
	send_data(0x41);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0xf9);
	send_data(0xff);
	c = send_data(0xff);
	StdIo_PrintFormat("%02x\n", (int)c);
	send_data(0xff);
	
	Time_Wait(1000);
	send_data(0x41);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0xf9);
	send_data(0xff);
	c = send_data(0xff);
	StdIo_PrintFormat("%02x\n", (int)c);
	send_data(0xff);
	
	
	send_data(0x51);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x00);
	send_data(0x01);
	send_data(0xff);
	for ( i = 0; i < 512 + 16; i++ )
	{
		c = send_data(0xff);
		StdIo_PrintFormat("%02x ", (int)c);
	}
	
	return 0;
}



int Boot_Process(VPARAM Param);


void Boot_Task(VP_INT exinf)
{
	T_SYSTEM_INITIALIZE_INF	SysInf;
	
	
	/*************************/
	/*       ������          */
	/*************************/
	
	/* �V�X�e�������� */
	memset(&SysInf, 0, sizeof(SysInf));
	SysInf.pSysMemBase     = SYSTEM_HEAP_ADDR;
	SysInf.SysMemSize      = SYSTEM_HEAP_SIZE;
	SysInf.SysMemAlign     = 8;
	SysInf.pIoMemBase      = NULL;
	SysInf.SystemStackSize = 2048;
	SysInf.pfncBoot        = Boot_Process;
	SysInf.BootParam       = (VPARAM)0;
	SysInf.BootStackSize   = 2048;
	System_Initialize(&SysInf);
}


/* �u�[�g�v���Z�X */
int Boot_Process(VPARAM Param)
{
	T_PROCESS_CREATE_INF	ProcInf;
	HANDLE					hProcess;
	HANDLE					hDriver;
	HANDLE					hTty;
	HANDLE					hCon;
	
	
	/*************************/
	/*   �f�o�C�X�h���C�o    */
	/*************************/
	
	/* �^�C�}������ */	
	OsTimer_Initialize();

	/* MMC�h���C�o���� */
	hDriver = MmcDrv_Create();
	File_AddDevice("mmc0", hDriver);

	/* Jelly UART �f�o�h������ (/dev/com0 �ɓo�^) */
	hDriver = JellyUartDrv_Create((void *)0xf2000000, 1, 2, 256);
	File_AddDevice("com0", hDriver);

	/* �V���A�����J�� */
	hTty = File_Open("/dev/com0", FILE_OPEN_READ | FILE_OPEN_WRITE);
	
	/* �V���A����ɃR���\�[���𐶐�( /dev/con0 �ɓo�^) */
	hDriver = Vt100Drv_Create(hTty);
	File_AddDevice("con0", hDriver);
	
	/* �R���\�[�����J�� */
	hCon = File_Open("/dev/con0", FILE_OPEN_READ | FILE_OPEN_WRITE);
	

	
	/*************************/
	/*     �W�����o�͐ݒ�    */
	/*************************/
	
	Process_SetTerminal(HANDLE_NULL, hTty);
	Process_SetConIn(HANDLE_NULL, hCon);
	Process_SetConOut(HANDLE_NULL, hCon);
	Process_SetStdIn(HANDLE_NULL, hCon);
	Process_SetStdOut(HANDLE_NULL, hCon);
	Process_SetStdErr(HANDLE_NULL, hCon);
	
	
	/*************************/
	/*     �R�}���h�o�^      */
	/*************************/
	Command_AddCommand("sh",       Shell_Main);
	Command_AddCommand("ps",       ProcessList_Main);
	Command_AddCommand("help",     CommandList_Main);
	Command_AddCommand("time",     TimeCmd_Main);
	Command_AddCommand("memdump",  MemDump_Main);
	Command_AddCommand("memwrite", MemWrite_Main);
	Command_AddCommand("memtest",  MemTest_Main);
	Command_AddCommand("keytest",  KeyTest_Main);
	Command_AddCommand("hello",    Hello_Main);
	Command_AddCommand("ls",       FileList_Main);
	Command_AddCommand("cp",       FileCopy_Main);
	Command_AddCommand("cat",      FileCat_Main);
	Command_AddCommand("filedump", FileDump_Main);
	Command_AddCommand("fatmount", FatMount_Main);
	
	Command_AddCommand("test",     test_main);
	
	
	/*************************/
	/*    �N�����b�Z�[�W     */
	/*************************/

	StdIo_PutString(
			"\n\n"
			"================================================================\n"
			" Hyper Operating System  Application Framework\n"
			"\n"
			"                          Copyright (C) 1998-2008 by Project HOS\n"
			"                          http://sourceforge.jp/projects/hos/\n"
			"================================================================\n"
			"\n");
	
	
	/*************************/
	/*      �V�F���N��       */
	/*************************/
	
	/* �v���Z�X�̐���*/
	ProcInf.pszCommandLine = "sh -i";								/* ���s�R�}���h */
	ProcInf.pszCurrentDir  = "/";									/* �N���f�B���N�g�� */
	ProcInf.pfncEntry      = NULL;									/* �N���A�h���X */
	ProcInf.Param          = 0;										/* ���[�U�[�p�����[�^ */
	ProcInf.StackSize      = 2048;									/* �X�^�b�N�T�C�Y */
	ProcInf.Priority       = PROCESS_PRIORITY_NORMAL;				/* �v���Z�X�D��x */
	ProcInf.hTerminal      = Process_GetTerminal(HANDLE_NULL);		/* �^�[�~�i�� */
	ProcInf.hConIn         = Process_GetConIn(HANDLE_NULL);			/* �R���\�[������ */
	ProcInf.hConOut        = Process_GetConOut(HANDLE_NULL);		/* �R���\�[���o�� */
	ProcInf.hStdIn         = Process_GetStdIn(HANDLE_NULL);			/* �W������ */
	ProcInf.hStdOut        = Process_GetStdOut(HANDLE_NULL);		/* �W���o�� */
	ProcInf.hStdErr        = Process_GetStdErr(HANDLE_NULL);		/* �W���G���[�o�� */
	for ( ; ; )
	{
		hProcess = Process_CreateEx(&ProcInf);
		Process_WaitExit(hProcess);
		Process_Delete(hProcess);
	}
}


/* end of file */
