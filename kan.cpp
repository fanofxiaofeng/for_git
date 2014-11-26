#include "a.h"
extern int a;
int g(void){
	a = 65;
	return a;
}
