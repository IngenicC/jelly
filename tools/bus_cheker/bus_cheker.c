#include <stdio.h>
#include <stdlib.h>


#define TABLE_SIZE		(8*1024*1024)

int				table_num = 0;
unsigned char	table_valid[TABLE_SIZE];
unsigned long	table_addr[TABLE_SIZE];
unsigned long	table_data[TABLE_SIZE];


int search_table(unsigned long addr)
{
	int i;
	
	for (i = 0; i < table_num; i++ )
	{
		if ( addr == table_addr[i] )
		{
			return i;
		}
	}
	
	return -1;
}


void write_table(unsigned long addr, unsigned long data, unsigned long sel)
{
	int index;

	index = search_table(addr);
	if ( index < 0 )
	{
		if ( table_num + 1 >= TABLE_SIZE )
		{
			return;
		}
		index = table_num++;
	}
	
	table_valid[index] |= sel;
	table_addr[index]   = addr;
	if ( sel & 0x1 ) { table_data[index] = ((table_data[index] & 0xffffff00) | (data & 0x000000ff)); }
	if ( sel & 0x2 ) { table_data[index] = ((table_data[index] & 0xffff00ff) | (data & 0x0000ff00)); }
	if ( sel & 0x4 ) { table_data[index] = ((table_data[index] & 0xff00ffff) | (data & 0x00ff0000)); }
	if ( sel & 0x8 ) { table_data[index] = ((table_data[index] & 0x00ffffff) | (data & 0xff000000)); }
}


int read_table(unsigned long addr, unsigned long data, unsigned long sel)
{
	int      index;
	
	index = search_table(addr);
	if ( index >= 0 )
	{
		if ( data != table_data[index] )
		{
			printf("exp:%08lx\n", table_data[index]);
			return 0;
		}
		return 1;
	}
	else
	{
		printf("read error\n");
		return 0;
	}
}


int main(int argc, char *argv[])
{
	FILE			*fp;
	unsigned long	time;
	unsigned long	addr;
	unsigned long	data;
	unsigned long	sel;
	char			module[256];
	char			buf[256];
	char			c;
	
	if ( argc < 2 )
	{
		return 1;
	}
	
	// �����l�ǂݍ���
	if ( argc >= 3 )
	{
		if ( (fp = fopen(argv[2], "r")) == NULL )
		{
			return 1;
		}
		
		addr = 0;
		while ( fgets(buf, sizeof(buf), fp) != NULL )
		{
			if ( sscanf(buf, "%lx", &data) != 1 )
			{
				break;
			}
			table_valid[table_num] = 0xf;
			table_addr[table_num]  = addr;
			table_data[table_num]  = data;
			table_num++;
			addr += 4;
		}
		
		fclose(fp);
	}
	
	
	// �`�F�b�N
	if ( (fp = fopen(argv[1], "r")) == NULL )
	{
		return 1;
	}
	while ( fgets(buf, sizeof(buf), fp) != NULL )
	{
		if ( sscanf(buf, "%ld %s %c %lx %lx %lx", &time, &module, &c, &addr, &data, &sel) != 6 )
		{
			printf("%s", buf);
		}
		
		if ( addr >= 0xf0000000 ) continue;

		if ( c == 'w' )
		{
			write_table(addr, data, sel);
		}
		else if ( c == 'r' )
		{
			if ( !read_table(addr, data, sel) )
			{
				printf("%s", buf);
			}
		}
	}

	return 0;
}


