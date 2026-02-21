import mrcfile
import os
import sys
from multiprocessing import Pool
import time
import shutil
import gzip

nproc = 8

def write_mrc(data, fname_out):
    t0 = time.time()
    # Gzip compression by mrcfile is too slow because the compression level is high.
    # mrc = mrcfile.new(fname_out, overwrite=True, compression='gzip')
    # mrc.set_data(data)
    fname_temp = os.path.join('/dev/shm', os.path.basename(fname_out)[:-3])
    mrcfile.write(fname_temp, data)
    with open(fname_temp, 'rb') as f_in:
        with gzip.open(fname_out, 'wb', compresslevel=6) as f_out:
            shutil.copyfileobj(f_in, f_out)
    os.remove(fname_temp)
    print(("[{}] Done in {:.3f}".format(os.path.basename(fname_out),
                                        time.time() - t0)))

def mrcs2mrc(mrcs_in):
    mrcs = mrcfile.mmap(mrcs_in)
    nimage = mrcs.data.shape[0]
    print("MRCS file {} has been opened. ({:d} images)".format(mrcs_in, nimage))

    prefix = os.path.basename(mrcs_in)[:os.path.basename(mrcs_in).find(".mrc")]
    print("[{}] converting...".format(prefix))

    tt1 = time.time()

    params = []
    for i in range(mrcs.data.shape[0]):
        fname_out = os.path.join("{}_{:03d}.mrc.gz".format(prefix,i+1))
        params.append((mrcs.data[i], fname_out))
    
    pool = Pool(nproc)
    pool.starmap(write_mrc, params)

    tt2 = time.time()

    print("[{}] Done in {:5.3f} sec.".format(prefix, tt2-tt1))


if __name__ == '__main__':
    mrcs_in = sys.argv[1]
    mrcs2mrc(mrcs_in)
        
