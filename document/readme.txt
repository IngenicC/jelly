-------------------------------------------------------------------------------
 Jelly -- �\�t�g�R�A�v���Z�b�V���O�V�X�e��

                                    Copyright (C) 2008-2009 by Ryuji Fuchikami 
                                    http://homepage3.nifty.com/ryuz
-------------------------------------------------------------------------------


1. �͂��߂�

  Jelly �Ƃ́AFPGA������ MIPS-I ���C�N�Ȗ��߃Z�b�g�̃R�A��L�����\�t�g�R�A
�v���Z�b�V���O�V�X�e���ł��B
  �]���}�C�R���Ő��䂵�Ă�������ŁA�����`�b�v�}�C�R����FPGA�Œu��������
�P�[�X�������Ă��܂����B
  ���̂悤�ȃP�[�X��z�肵�āA�g���݃\�t�g�J���̎��_����g���₷���V�X�e����
�ڎw���ĊJ�����s���Ă���܂��B


2. �\��

  +document              �e��h�L�������g
  +rtl
  |  +cpu                CPU�R�A
  |  +cache              �L���b�V��������
  |  +bus                �o�X�ϊ��Ȃǂ̃��W���[��
  |  +library            �e�탉�C�u�����I���W���[��
  |  +irc                �����݃R���g���[��
  |  +ddr_sdram          DDR-SDRAM�R���g���[��
  |  +sram               ����SRAM
  |  +extbus             �O���o�X����
  |  +uart               UART
  |  +timer              �^�C�}
  |  +gpio               GPIO
  +projects
  |  +spartan3e_starter  Spartan-3E Starter Kit �p�v���W�F�N�g
  |  +spartan3_starter   Spartan-3 Starter Kit �p�v���W�F�N�g
  |  +cq-frk-s3e2        DesignWave���܂� Spartan-3�{�[�h�p�v���W�F�N�g
  +soft                  ROM���\�t�g�����p
  +tools                 �c�[����



-------------------------------------------------------------------------------
 end of file
-------------------------------------------------------------------------------
