import mrcfile

def find_beam_center_cv(fin):
    import cv2
    mrc = mrcfile.mmap(fin)
    nimage = mrc.data.shape[0]
    img = mrc.data[int(nimage/2)]

    img_blur = cv2.blur(img, (3,3))

    ret, thresh = cv2.threshold(img_blur, 10000, 255, cv2.THRESH_BINARY)
    thresh = thresh.astype('uint8')
    
    contours, hierarchy = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    i_max = 0
    s_max = 0
    for i in range(len(contours)):
        #print(i, cv2.contourArea(contours[i]))
        if cv2.contourArea(contours[i]) > s_max:
            i_max = i
            s_max = cv2.contourArea(contours[i])

    (x, y), r = cv2.minEnclosingCircle(contours[i_max])
    print("{:d},{:d},{:.1f}".format(int(x), int(y), r))

def find_beam_center_ndimage(fin):
    from scipy import ndimage
    import numpy as np

    # check whether input mrc file is compressed or not
    if fin.endswith('.mrc'):
        mrc = mrcfile.mmap(fin)
    else:
        mrc = mrcfile.open(fin)
    
    if len(mrc.data.shape) == 2: # single image
        img = mrc.data
    else: # stack of images
        nimage = mrc.data.shape[0]
        img = mrc.data[int(nimage/2)]

    # filter noises in the image
    blurred_img = ndimage.gaussian_filter(img, sigma=3)
    # binarization of image with the threshold as a half of maximum
    bin_img = np.where((blurred_img > np.max(blurred_img)/2), 255, 0)
    # detect and label connected regions in the binarized image
    label_im, nb_label = ndimage.label(bin_img)
    # print("Number of labels: ", nb_label)

    # find the largest labeled regions
    idx = 0
    max_area = 0
    for i in range(nb_label):
        a = np.count_nonzero(label_im == i+1)
        if a > max_area:
            idx = i
            max_area = a

    # calculate the center and diameter of the region
    loc = ndimage.find_objects(label_im)[idx]
    x = (loc[1].start+loc[1].stop)/2
    y = (loc[0].start+loc[0].stop)/2
    r = min((loc[1].stop-loc[1].start)/2,
            (loc[0].stop-loc[0].start)/2)

    print("{:d},{:d},{:.1f}".format(int(x), int(y), r))

if __name__ == '__main__':
    import sys

    fin = sys.argv[1]
    find_beam_center_ndimage(fin)
    #find_beam_center_cv(fin)
