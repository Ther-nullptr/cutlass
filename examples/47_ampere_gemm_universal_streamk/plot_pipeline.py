import matplotlib.pyplot as plt
import matplotlib.patches as patches

FIXED_WIDTH = 0.5
SCALE = 1000
ticks = []

def draw_adjustable_rectangle(ax: plt.Axes, start_locate: float, end_locate: float, width_locate: float, x_limit: float = 30, y_limit: float = 10):
    assert start_locate < end_locate
    height = end_locate - start_locate

    # Draw the rectangle
    rectangle = patches.Rectangle((start_locate, width_locate), height,
                                  FIXED_WIDTH, linewidth=1, edgecolor='r', facecolor='none')
    ax.add_patch(rectangle)
    ax.axis('scaled')
    ticks.append(end_locate)


def grid_and_save(ax: plt.Axes, pic_name: str):
    ax.grid(which='major', axis='x', linestyle='--')
    ax.invert_yaxis()
    ax.set_xticks(ticks)
    ax.set_xlabel('clocks/(1000 cycles)')
    ax.set_ylabel('stage')
    ax.set_title(pic_name)
    plt.savefig(pic_name + '.png')


if __name__ == '__main__':
    stage = 6
    shape = (2048, 128, 8192)
    fig, ax = plt.subplots()
    fig.set_size_inches(20, 16)
    pic_name = f'stage_{stage}_shape_{shape[0]}_{shape[1]}_{shape[2]}'
    start_time = 1655.18
    sync_time = [
        365.364,
        671,
        1035.55,
        1680.82,
        1907.73,
        2291.45,
        2508.73,
        3136.64,
        3363.18,
        3780.09,
        4044.91,
        4570.91,
        4712,
        5300.55,
        5382.64,
        5813.09,
        6089.55,
        6742.09,
        7007.27,
        7493,
        7840.18,
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
