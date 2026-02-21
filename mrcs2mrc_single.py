import mrcfile
import os
import sys

def mrcs2mrc(mrcs_in):
    mrcs = mrcfile.mmap(mrcs_in)
    nimage = mrcs.data.shape[0]
    print("MRCS file {} has been opened. ({:d} images)".format(mrcs_in, nimage))

    #dirbase = os.path.dirname(mrcs_in)
    prefix = os.path.basename(mrcs_in)[:os.path.basename(mrcs_in).find(".mrc")]
    #prefix = "_".join(os.path.basename(mrcs_in).split("_")[:3])

    #target_dir = os.path.join(dirbase, prefix)
    #os.makedirs(target_dir)
    #print("Directory {} has been made.".format(target_dir))
    print("[{}] converting...".format(prefix))

    for i in range(mrcs.data.shape[0]):
        #fname_out = os.path.join(target_dir,
        #                         "{}_{:03d}.mrc.bz2".format(prefix,i+1))
        fname_out = "{}_{:03d}.mrc.gz".format(prefix,i+1)
        with mrcfile.new(fname_out, overwrite=True, compression='gzip') as mrc:
            mrc.set_data(mrcs.data[i])

        print(fname_out)

    print("[{}] Done".format(prefix))


if __name__ == '__main__':
    mrcs_in = sys.argv[1]
    mrcs2mrc(mrcs_in)

