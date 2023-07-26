import matplotlib.pyplot as plt

if __name__ == '__main__':
    stage = 4
    gemm_shape = (128, 128, 128)
    thread_block_shape = (16, 16, 4)
    plot_title = f'gemm_shape={gemm_shape}, thread_block_shape={thread_block_shape}'