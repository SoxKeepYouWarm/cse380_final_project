extern int lab6(void);	
extern int pin_connect_block_setup_for_uart0(void);


int main()
{ 	
	pin_connect_block_setup_for_uart0();
	lab6();
}
