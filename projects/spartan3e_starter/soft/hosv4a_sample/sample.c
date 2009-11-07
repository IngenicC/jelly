/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  sample.c
 * @brief %jp{�T���v���v���O����}%en{Sample program}
 *
 * Copyright (C) 1998-2009 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include <stdlib.h>
#include <string.h>
#include "kernel.h"
#include "kernel_id.h"
#include "uart.h"


#define LEFT(num)	((num) <= 1 ? 5 : (num) - 1)
#define RIGHT(num)	((num) >= 5 ? 1 : (num) + 1)


/** %jp{�������n���h��} */
void Sample_Initialize(VP_INT exinf)
{
	/* %jp{UART������} */
	Uart_Initialize();
	
	/* %jp{�^�X�N�N��} */
	act_tsk(TSKID_SAMPLE1);
	act_tsk(TSKID_SAMPLE2);
	act_tsk(TSKID_SAMPLE3);
	act_tsk(TSKID_SAMPLE4);
	act_tsk(TSKID_SAMPLE5);
}


/** %jp{�K���Ȏ��ԑ҂�} */
void Sample_RandWait(void)
{
	static unsigned long seed = 12345;
	unsigned long r;
	
	wai_sem(SEMID_RAND);
	seed = seed * 22695477UL + 1;
	r = seed;
	sig_sem(SEMID_RAND);
	
	dly_tsk((r % 1000) + 100);
}


/** %jp{��ԕ\��} */
void Sample_PrintSatet(int num, const char *text)
{
	int	i;
	
	wai_sem(SEMID_UART);
	
	/* %jp{������o��} */
	Uart_PutChar('0' + num);
	Uart_PutChar(' ');
	Uart_PutChar(':');
	Uart_PutChar(' ');
	for ( i = 0; text[i] != '\0'; i++ )
	{
		Uart_PutChar(text[i]);
	}
	Uart_PutChar('\r');
	Uart_PutChar('\n');
	
	sig_sem(SEMID_UART);
}



/** %jp{�T���v���^�X�N} */
void Sample_Task(VP_INT exinf)
{
	int num;
	
	num = (int)exinf;
	
	/* %jp{������N�w�҂̐H���̖��} */
	for ( ; ; )
	{
		/* %jp{�K���Ȏ��ԍl����} */
		Sample_PrintSatet(num, "thinking");
		Sample_RandWait();
		
		/* %jp{���E�̃t�H�[�N�����܂Ń��[�v} */
		for ( ; ; )
		{
			/* %jp{�����珇�Ɏ��} */
			wai_sem(LEFT(num));
			if ( pol_sem(RIGHT(num)) == E_OK )
			{
				break;	/* %jp{������ꂽ} */
			}
			sig_sem(LEFT(num));	/* %jp{���Ȃ���Η���} */
			
			/* %jp{�K���Ȏ��ԑ҂�} */
			Sample_PrintSatet(num, "hungry");
			Sample_RandWait();
			
			/* %jp{�E���珇�Ɏ��} */
			wai_sem(RIGHT(num));
			if ( pol_sem(LEFT(num)) == E_OK )
			{
				break;	/* %jp{������ꂽ} */
			}
			sig_sem(RIGHT(num));	/* %jp{���Ȃ���Η���} */
			
			/* %jp{�K���Ȏ��ԑ҂�} */
			Sample_PrintSatet(num, "hungry");
			Sample_RandWait();
		}
		
		/* %jp{�K���Ȏ��ԁA�H�ׂ�} */
		Sample_PrintSatet(num, "eating");
		Sample_RandWait();
		
		/* %jp{�t�H�[�N��u��} */
		sig_sem(LEFT(num));
		sig_sem(RIGHT(num));
	}
}


/* end of file */
