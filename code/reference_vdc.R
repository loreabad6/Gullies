library(igraph)
library(sf)
# library(sfdep)
library(stars)
# library(terra)
library(tidyverse)
# library(tmap)

# dem = rast('data/Mangatu_feature_extraction/Mangatu_LiDAR_DEM_2019.tif')
# sl = terrain(dem, "slope", unit = "radians")
# as = terrain(dem, "aspect", unit = "radians")
# hs = shade(
#   sl, as, 
#   angle = 45, 
#   direction = 300,
#   normalize= TRUE
# )

ref = read_sf('data/reference/gullies.shp')
ref |> 
  mutate(area = st_area(geometry)) |> 
  st_drop_geometry() |> 
  group_by(year) |> 
  summarise(
    count = n(),
    area = sum(area)
  )

int = st_intersects(ref)
g = graph.adjlist(int)
c = components(g)

refint = ref |> 
  mutate(
    id = row_number(),
    year = as.Date(ISOdate(year, 1, 1)), 
    gid = as.factor(c$membership)
  ) |> 
  arrange(year)

st_write(refint, 'data/reference/gullies_grouped.gpkg')

st_bbox_by_feature = function(x) {
  f <- function(y) st_as_sfc(st_bbox(y))
  do.call("c", lapply(x, f))
}

refint_bbox  = refint |> 
  group_by(gid) |> 
  summarise(geometry = st_union(geometry)) |> 
  mutate(geometry = (st_bbox_by_feature(geometry))) |> 
  st_set_crs(2193)

st_write(refint_bbox, 'data/reference/gullies_bbox.gpkg')

refint_st = refint |> 
  group_by(gid, year) |> 
  summarise(geometry = st_union(geometry))

refint_st_filled = refint_st |> 
  ungroup() |> 
  complete(gid, year) |> 
  st_as_sf()

a = array(
  0L, 
  c(
    length(unique(refint_st_filled$gid)),
    length(unique(refint_st_filled$year))
  ),
  dimnames = list(
    gid = unique(refint_st_filled$gid),
    year = unique(refint_st_filled$year)
  )
)

d = st_dimensions(
  gid = st_geometry(refint_st_filled),
  year = unique(refint_st_filled$year)
)

test = st_as_stars(list(n = a), dimensions = d)
test |> plot()


mat = as.matrix(refint_st_filled[c('gid','year')])
