import matplotlib.pyplot as plt
import matplotlib.patches as patches

FIXED_WIDTH = 0.5
SCALE = 2000
ticks = []

def draw_adjustable_rectangle(ax: plt.Axes, start_locate: float, end_locate: float, width_locate: float, x_limit: float = 30, y_limit: float = 10):
    assert start_locate < end_locate
    height = end_locate - start_locate

    # Draw the rectangle
    rectangle = patches.Rectangle((start_locate, width_locate), height,
                                  FIXED_WIDTH, linewidth=1, edgecolor='r', facecolor='none')
    # plot a num in the middle of the rectangle
    ax.text(start_locate + height / 2, width_locate + FIXED_WIDTH / 2, f'{height * SCALE:.2f}', ha='center', va='center')
    ax.add_patch(rectangle)
    ax.axis('scaled')
    ticks.append(end_locate)


def grid_and_save(ax: plt.Axes, pic_name: str):
    ax.grid(which='major', axis='x', linestyle='--')
    ax.invert_yaxis()
    ax.set_xticks(ticks)
    ax.set_xlabel(f'clocks/({SCALE} cycles)')
    ax.set_ylabel('stage')
    ax.set_title(pic_name)
    plt.savefig(pic_name + '.png')


if __name__ == '__main__':
    stage = 6
    shape = (4096, 4096, 4096)
    thread_block = (128, 128, 32)
    warp_num = 4
    fig, ax = plt.subplots()
    fig.set_size_inches(20, 16)
    pic_name = f'stage_{stage}_shape_{shape[0]}_{shape[1]}_{shape[2]}_thread_block_{thread_block[0]}_{thread_block[1]}_{thread_block[2]}_warp_num_{warp_num}'
    start_time = 2127.95
    sync_time = [
        995.727,
        1660.27,
        2192.73,
        2972.09,
        3418.55,
        4024.55,
        4560.09,
        5190.09,
        5608.73,
        6294.27,
        6743.27,
    ]
    # scale the time
    start_time /= SCALE
    sync_time = [i / SCALE for i in sync_time]

    # Set axis limits
    ax.set_xlim(0, sync_time[-1] + start_time)
    ax.set_ylim(0, (len(sync_time) + 1) * FIXED_WIDTH)
    # div 10 to scale
    # start_time /= 500
    # sync_time = [i / 500 for i in sync_time]

    for i in range(len(sync_time) + 1):
        if (i == 0):
            draw_adjustable_rectangle(ax, 0, start_time, FIXED_WIDTH*i)
        elif (i < stage - 1):
            draw_adjustable_rectangle(ax, 0, start_time + sync_time[i - 1], FIXED_WIDTH*i)
        elif (i == stage - 1):
            draw_adjustable_rectangle(ax, start_time, start_time + sync_time[i - 1], FIXED_WIDTH*i)
        else:
            draw_adjustable_rectangle(ax, start_time + sync_time[i - stage], start_time + sync_time[i - 1], FIXED_WIDTH*i)
        # plt.axis('scaled')

    grid_and_save(ax, pic_name)
