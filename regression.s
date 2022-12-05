.section .rodata
	cdouble_0: .double 0.00
	cdouble_2: .double 2.00

.section .data
	value_msg: .asciz "value: %f\n"
	loss_msg: .asciz "loss: %f\n"
	loss_grad_msg: .asciz "loss gradient: %f\n"
	result_msg: .asciz "\nintercept: %f\ncoefficient: %f\n"
	intercept: .double 0.11
	coefficient: .double 0.51
	learning_rate: .double 0.001

	x_values: .double 1.12, 4.32, 5.55, 6.74, 8.88
	y_values: .double 2.22, 1.45, 5.23, 4.56, 6.73

.section .text
	.global main

# yhat = b0 + b1 * x
estimate:
	pushq %rbp
	movq %rsp, %rbp
	
	# xmm0 - x_values[i]

	movsd intercept(%rip), %xmm1
	movsd coefficient(%rip), %xmm4
	mulsd %xmm4, %xmm0
	addsd %xmm1, %xmm0

	leave
	ret
	
# loss function
# (y - yhat)^2
loss:
	pushq %rbp
	movq %rsp, %rbp

	# xmm0 - yhat
	# xmm1 - y 
	
	subsd %xmm0, %xmm1 # y -= yhat
	mulsd %xmm1, %xmm1 # y *= y
	movsd %xmm1, %xmm0

	leave
	ret

# loss gradient for the coefficient
# 2(y - yhat)*x
loss_gradient_coefficient:
	pushq %rbp
	movq %rsp, %rbp

	# xmm0 - yhat
	# xmm1 - y
	# xmm4 - x_values[i]
	
	subsd %xmm0, %xmm1 # y -= yhat
	mulsd cdouble_2(%rip), %xmm1 # y *= 2
	mulsd %xmm4, %xmm1
	movsd %xmm1, %xmm0

	leave
	ret

# loss gradient for the intercept
# 2(y - yhat)
loss_gradient_intercept:
	pushq %rbp
	movq %rsp, %rbp

	# xmm0 - yhat
	# xmm1 - y
	
	subsd %xmm0, %xmm1 # y -= yhat
	mulsd cdouble_2(%rip), %xmm1 # y *= 2
	movsd %xmm1, %xmm0

	leave
	ret

adjust_weights:
	pushq %rbp
	movq %rsp, %rbp

	# xmm0 - loss_gradient_b0
	# xmm1 - loss_gradient_b1

	# NOTE: loss gradient is negative so we "add" it here

	# b0 -= loss_gradient_b0 * learning_rate
	movsd learning_rate(%rip), %xmm2
	mulsd %xmm2, %xmm0
	movsd intercept(%rip), %xmm3
	addsd %xmm0, %xmm3
	movsd %xmm3, intercept(%rip)

	# b1 -= loss_gradient_b1 * learning_rate
	mulsd %xmm2, %xmm1
	movsd coefficient(%rip), %xmm3
	addsd %xmm1, %xmm3
	movsd %xmm3, coefficient(%rip)

	leave
	ret


fit:
	pushq %rbp
	movq %rsp, %rbp

	subq $48, %rsp

	# rdi - pointer to x_values
	# rsi - pointer to y_values
	# rdx - length of both arrays
	# rcx - total_iterations

	movq %rcx, -40(%rbp) # total_iterations 
	movq $0, -32(%rbp) # current_iter = 0

fit_begin_train:
	xor %rbx, %rbx # set counter = 0
	xor %rax, %rax # set array idx = 0

	# NOTE:
	# b0 = intercept
	# b1 = coefficient
	movsd cdouble_0(%rip), %xmm0
	movsd cdouble_0(%rip), %xmm1
	movsd cdouble_0(%rip), %xmm2 # set total_loss = 0
	movsd cdouble_0(%rip), %xmm3 # set total_loss_grad_b0 = 0	
	movsd cdouble_0(%rip), %xmm4
	movsd cdouble_0(%rip), %xmm5 # set total_loss_grad_b1 = 0
	
fit_begin_calc_grad:
	movsd (%rdi, %rax, 8), %xmm0 # x_values[i]
	movsd (%rsi, %rax, 8), %xmm1 # y_values[i]
	
	movsd %xmm0, -8(%rbp) 	# x_values[i]
	movsd %xmm1, -16(%rbp) 	# y_values[i]

	call estimate
	movsd %xmm0, -24(%rbp) # yhat

	movsd -16(%rbp), %xmm1
	call loss

	addsd %xmm0, %xmm2 # total_loss += loss(x_values[i], y_values[i])

	movsd -24(%rbp), %xmm0
	movsd -16(%rbp), %xmm1
	movsd -8(%rbp), %xmm4
	call loss_gradient_coefficient

	addsd %xmm0, %xmm5 # total_loss_grad_b1 += loss_grad(x_values[i], y_values[i])

	movsd -24(%rbp), %xmm0
	movsd -16(%rbp), %xmm1
	call loss_gradient_intercept

	addsd %xmm0, %xmm3 # total_loss_grad_b0 += loss_grad(x_values[i], y_values[i])

	incq %rbx # counter++
	incq %rax # index++
	cmp %rdx, %rbx
	jl fit_begin_calc_grad # if (counter < length) goto fit_begin_calc_grad
fit_end_calc_grad:
	movsd %xmm3, %xmm0
	movsd %xmm5, %xmm1
	call adjust_weights

	incq -32(%rbp)
	movq -32(%rbp), %r8
	movq -40(%rbp), %rcx
	cmp %rcx, %r8 # if (current_iter < iter) goto fit_begin_train
	jl fit_begin_train
fit_end_train:
	leave
	ret

main:
	pushq %rbp
	movq %rsp, %rbp

	leaq x_values(%rip), %rdi
	leaq y_values(%rip), %rsi
	movq $5, %rdx
	movq $10000, %rcx
	call fit

	movsd intercept(%rip), %xmm0
	movsd coefficient(%rip), %xmm1
	leaq result_msg(%rip), %rdi
	movq $2, %rax
	call printf

	xor %rax, %rax
	call exit

	leave
	ret
