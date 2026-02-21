import mrcfile
import os
import sys
import argparse
import numpy as np
from multiprocessing import Pool
import time

def write_mrc(data, gain, scale, fname_out):
    mrc = mrcfile.new(fname_out, overwrite=True, compression='gzip')
    mrc.set_data(np.rint(data * gain * scale).astype(np.int16))
    print(("[{}] Done".format(os.path.basename(fname_out))))

def write_mrc2(mrc_in, gain, scale, target_dir, prefix, index_list):
    for i in index_list:
        t1 = time.time()
        fname_out = os.path.join(target_dir,
                                 "{}_{:03d}.mrc.gz".format(prefix, i+1))
        data = mrcfile.mmap(mrc_in).data[i]
        mrc = mrcfile.new(fname_out, overwrite=True, compression='gzip')
        mrc.set_data(np.rint(data * gain * scale).astype(np.int16))
        mrc.close()
        t2 = time.time()
        print(("[{}] Done in {:.3f} sec.".format(os.path.basename(fname_out)), t2-t1))


def mrcs2mrc(mrcs_in, gain_ref=None, scale=1, target_dir=None, nproc=1):
    mrcs = mrcfile.mmap(mrcs_in)
    nimage = mrcs.data.shape[0]
    print("MRCS file {} has been opened. ({:d} images)".format(mrcs_in, nimage))

    if gain_ref != None:
        gain = mrcfile.open(gain_ref).data
        print("Gain reference file {} has been opened.".format(gain_ref))
    else:
        gain = np.ones(mrcs.data.shape[1], mrcs.data.shape[2])

    dirbase = os.path.dirname(mrcs_in)
    prefix = os.path.basename(mrcs_in)[:os.path.basename(mrcs_in).find(".mrc")]
    #prefix = "_".join(os.path.basename(mrcs_in).split("_")[:3])

    if target_dir == None:
        target_dir = "."
    # os.makedirs(target_dir)
    # print("Directory {} has been made.".format(target_dir))
    print("[{}] converting...".format(prefix))

    # params = []
    # for i in range(mrcs.data.shape[0]):
    #     fname_out = os.path.join("{}_{:03d}.mrc.gz".format(prefix,i+1))
    #     # params.append((mrcs.data[i], gain.data, int(scale), fname_out))
    #     params.append((mrc_in, i, gain.data, int(scale), fname_out))
    
    params = []
    for i in range(nproc):
        params.append((mrcs_in, gain, scale, target_dir, prefix, [x for x in range(i, nimage, nproc)]))


    pool = Pool(nproc)
    # pool.starmap(write_mrc, params)
    pool.starmap(write_mrc2, params)

    print("[{}] Done".format(prefix))


if __name__ == '__main__':
    # mrcs_in = sys.argv[1]

    parser = argparse.ArgumentParser(
        prog="mrc2mrcs.py",
        description="Python script to output a series of signle mrc file from a mrcs stack file",
    )

    parser.add_argument('mrcsfile')
    parser.add_argument('-g', '--gain_ref')
    parser.add_argument('-s', '--scale', type=int)
    parser.add_argument('-d', '--dir_out')
    parser.add_argument('-p', '--nproc', type=int)
    # parser.add_arugment('-u', '--uncompress')

    args = parser.parse_args()

    mrcs2mrc(args.mrcsfile, args.gain_ref, args.scale, args.dir_out, args.nproc)
        
