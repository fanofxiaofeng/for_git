#include <stdio.h>

const int big = 250010;

int a[big];

void max_heapify(int, int);
void swap(int &, int &);
void show_median(int);

int main(){
	int n;
	scanf("%d", &n);

	for(int i = 1;i <= n;i++)
		scanf("%d", &a[i]);

	for(int i = n;i >= 1;i--)
		max_heapify(i, n);

	int copy = n;
	for(int i = copy;i > 1;i--){
		swap(a[i], a[1]);
		max_heapify(1, --n);
	}
	/*
	for(int i = 1;i <= copy;i++)
		printf("%d: %d\n", i, a[i]);
	*/
	show_median(copy);
	return 0;
}

void show_median(int n){
	int left;
	int right;
	if(n % 2 == 0){
		left = a[n / 2];
		right = a[n / 2 + 1];
	} else {
		left = a[n / 2 + 1];
		right = left;
	}
	int sum = left / 2 + right / 2;
	bool with_half = false;
	if(left % 2 == 1 && right % 2 == 1)
		sum++;
	else if(left % 2 == 0 && right % 2 == 0)
		;
	else
		with_half = true;

	printf("%d.%c\n", sum, (with_half?'5':'0'));
}

void max_heapify(int pos, int n){
	int record = pos;
	int left = 2 * pos;
	int right = left + 1;

	if(left <= n && a[left] > a[record])
		record = left;

	if(right <= n && a[right] > a[record])
		record = right;

	if(record != pos){
		swap(a[pos], a[record]);
		max_heapify(record, n);
	}
}

void swap(int &a, int &b){
	int temp = a;
	a = b;
	b = temp;
}
