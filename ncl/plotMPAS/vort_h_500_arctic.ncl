;=============================================================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;=============================================================================================

external mpas_vort_cell "./mpas_vort_cell.so"
external mpas_filter_cells "./mpas_filter_cells.so"

begin

;SET RESOURCES:
res = True
res@gsnDraw             = True
res@gsnFrame            = False
res@gsnMaximize         = True
res@gsnSpreadColors     = True

;res@mpProjection        = "CylindricalEquidistant"
res@mpProjection        = "Orthographic"
res@mpDataBaseVersion   = "MediumRes" 
res@mpCenterLatF        = 90
res@mpCenterLonF        = 0.
res@cnFillOn            = False
;res@cnFillMode          = "AreaFill"
res@cnFillMode          = "RasterFill"
res@cnRasterSmoothingOn = True
res@cnFillOn            = True
res@cnLinesOn           = False

sres = True
sres@gsnDraw   = False
sres@gsnFrame  = False
sres@cnFillOn  = False
sres@cnLinesOn = True
sres@cnLineLabelsOn = True
sres@cnLineThicknessF = 2.0
sres@cnLineLabelFontHeightF = 0.009 
sres@cnInfoLabelFontHeightF = 0.01          
sres@cnLineLabelPlacementMode = "Computed"
sres@cnLineLabelDensityF = 1.2


res@cnLevelSelectionMode = "ManualLevels"
res@cnMinLevelValF  =  -0.0003
res@cnMaxLevelValF  =  0.0003
res@cnLevelSpacingF =  0.000025

sres@cnLevelSelectionMode = "ManualLevels"
sres@cnMinLevelValF  =  4400.
sres@cnMaxLevelValF  =  6400.
sres@cnLevelSpacingF =  50.

wks = gsn_open_wks("png","vort_h_500_arctic")
gsn_define_colormap(wks,"BlueYellowRed")

;files = (/ \
;"/arctic1/nick/cases/v1.0/x4/august/x4.163842.tiedtke.output.2006-08-01_00.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-01_00.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-01_03.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-01_06.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-01_09.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-01_12.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-01_15.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-01_18.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-01_21.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-02_00.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/august/diagnostics.2006-08-02_03.00.00.nc"/)

;files = (/ \
;"/arctic1/nick/cases/v1.0/x1.163842.output.2006-07-24_12.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/x4.163842.tiedtke.output.2006-09-01_00.00.00.nc",\
;"/arctic1/nick/cases/v1.0/x4/2week/x4.163842.tiedtke.output.2006-07-24_12.00.00.nc"/)

;files = (/ \
;"/arctic1/nick/cases/v1.0/x4/test/x4.kf.output.2006-07-24_12.00.00.nc"/)

files = (/ \
"/arctic1/nick/cases/v1.0/x4/forSteven/x4.t0.output.2006-08-29_00.00.00.nc",\
"/arctic1/nick/cases/v1.0/x4/forSteven/diagnostics.2006-08-29_00.00.00.nc"/)

nfiles = dimsizes(files)

set_default_fillvalue("double",  -99999)

stride = 1

ff = addfile(files(0),"r")

r2d = 57.2957795 ; conversion from radians to degrees.
res@sfXArray = ff->lonCell(0::stride) * r2d
res@sfYArray = ff->latCell(0::stride) * r2d
sres@sfXArray = ff->lonCell(0::stride) * r2d
sres@sfYArray = ff->latCell(0::stride) * r2d
terrain_hgt_in = ff->zgrid(:,0)
terrain_hgt = terrain_hgt_in(0::stride)

verticesOnCell = ff->verticesOnCell
cellsOnCell = ff->cellsOnCell
nEdgesOnCell = ff->nEdgesOnCell
dv = dimsizes(verticesOnCell)
maxEdges = dv(1)

delete(ff)

;; loop over times

do nf = 0, nfiles(0)-1
;do nf = 1, nfiles(0)-1
;do nf = nfiles(0)-2, nfiles(0)-1

print("processing file "+files(nf))

ff = addfile(files(nf),"r")
fieldin1 = ff->height_500hPa(:,:)
fieldin_tmp = ff->vorticity_500hPa(:,:)

dims = dimsizes(fieldin_tmp)
nv = dims(1)
dims = dimsizes(fieldin1)
nc = dims(1)
fieldin = fieldin1

;nTime = dims(0)
nTime=1

do iTime=0,nTime-1

mpas_vort_cell::mpas_vort_cell1(nEdgesOnCell, verticesOnCell, maxEdges, nc, nv, fieldin_tmp(iTime,:), fieldin(iTime,:) )
nfilt=2
;mpas_filter_cells::mpas_filter_cells(nEdgesOnCell, cellsOnCell, maxEdges, nc, fieldin(iTime,:), nfilt )

field = fieldin(iTime,0::stride)
field1 = fieldin1(iTime,0::stride)
dimsf = dimsizes(field)
hdiff = abs(field1-terrain_hgt)

do i=0,dimsf(0)-1
  if(hdiff(i) .lt. 1.) then
    field(i) = -99999
    field1(i) = -99999
  end if
end do

;field@long_name = "500 hPa hgt, rel vort "+ff->xtime(iTime,0:18)
field@_FillValue = -99999
field1@_FillValue = -99999
print(" plotting time "+ff->xtime(iTime,0:18))
;field@units = "[m, s^-1]"

res@lbTitleString="1/s"
res@lbTitlePosition= "Bottom"
res@lbTitleFontHeightF= 0.018
res@lbTitleDirection= "Across"

sres@cnInfoLabelOn = False ;Turn off 'contour from x to y by z' that gets cut off

plot = gsn_csm_contour_map(wks,field,res)
plot_ov = gsn_csm_contour(wks,field1,sres)
overlay(plot,plot_ov)
draw(plot)
frame(wks)

end do

delete(ff)
delete(fieldin)
delete(fieldin1)
delete(fieldin_tmp)
end do

end

;=============================================================================================
