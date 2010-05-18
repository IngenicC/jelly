/** 
 *  Sample program for Hyper Operating System V4 Advance
 *
 * @file  ostimer.c
 * @brief %jp{OS�^�C�}}%en{OS timer}
 *
 * Copyright (C) 1998-2008 by Project HOS
 * http://sourceforge.jp/projects/hos/
 */


#include "kernel.h"
#include "ostimer.h"


#define TIMER0_CONTROL	((volatile UW *)0xfffff100)
#define TIMER0_COMPARE	((volatile UW *)0xfffff104)
#define TIMER0_COUNTER	((volatile UW *)0xfffff10c)

#define INTNO_TIMER0	0



static void OsTimer_Isr(VP_INT exinf);		/**< %jp{�^�C�}�����݃T�[�r�X���[�`��} */


/** %jp{OS�p�^�C�}���������[�`��} */
void OsTimer_Initialize(VP_INT exinf)
{
	T_CISR cisr;
	
	/* %jp{�����݃T�[�r�X���[�`������} */
	cisr.isratr = TA_HLNG;
	cisr.exinf  = 0;
	cisr.intno  = INTNO_TIMER0;
	cisr.isr    = (FP)OsTimer_Isr;
	acre_isr(&cisr);
	
	/* �J�n */
	*TIMER0_COMPARE = (50000 - 1);		/* 50Mhz / 50000 = 1kHz (1ms) */
	*TIMER0_CONTROL = 0x0002;			/* clear */
	*TIMER0_CONTROL = 0x0001;			/* start */
	
	/* �����݋��� */
	ena_int(INTNO_TIMER0);
}


/** %jp{�^�C�}�����݃n���h��} */
void OsTimer_Isr(VP_INT exinf)
{
	/* %jp{�v���N���A} */
	vclr_int(INTNO_TIMER0);
	
	/* %jp{�^�C���e�B�b�N����} */
	isig_tim();
}



/* end of file */
