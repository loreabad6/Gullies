library(sf)
library(stars)
library(here)
library(tidyverse)
library(patchwork)

ref_dir = here("from262/gullies/dump_15082021/reference/")
output_dir = here("from262/gullies/dump_15082021/output/")
output_fs = list.files(
  output_dir,
  pattern = "^lsfctshadetridx_train.*shp$", 
  full.names = TRUE
)
output_name = list.files(
  output_dir,
  pattern = "^lsfctshadetridx_train.*shp$", 
  full.names = FALSE
) %>% str_extract("pad[0-9]+") %>% 
  str_extract("[0-9]+")

read_id = function(x, name) {
  read_sf(x) %>% 
    mutate(pad = as.numeric(name))
}
detectedObjects = map2(output_fs, output_name, read_id) %>% 
  bind_rows() %>% 
  arrange(Confidence)

train = here(ref_dir, "gullies_train.shp") %>% 
  read_sf() %>% 
  st_transform(st_crs(detectedObjects))
test = here(ref_dir, "gullies_test.shp") %>% 
  read_sf() %>% 
  st_transform(st_crs(detectedObjects))


detectedObjects = detectedObjects %>% 
  mutate(area = as.numeric(st_area(geometry)))

detectedObjectsFiltered = detectedObjects %>% 
  filter(area > 2000 | Confidence > 80)


ggplot(detectedObjectsFiltered) +
  geom_histogram(aes(Confidence)) +
  facet_wrap(~pad)


ggplot(detectedObjectsFiltered) +
  aes(Confidence, area) +
  geom_point() +
  geom_smooth(method = "loess") +
  scale_y_continuous(trans = "log10") +
  facet_wrap(~pad) 

dist = ggplot(detectedObjectsFiltered) +
  geom_sf(aes(fill = Confidence), col = NA) +
  scale_fill_viridis_c() +
  theme_void() +
  theme(panel.background = element_rect(fill = "black")) 

ref = ggplot() +
  geom_sf(data = train, col = 'red', fill = NA) +
  geom_sf(data = test, col = 'orange', fill = NA) +
  theme_void() 
dims = get_dim(dist)
ref_aligned = set_dim(ref, dims)

ggsave(dist, filename = 'exploration/distribution.png',
       width = 20, height = 18, units = 'cm', dpi = 300)
ggsave(ref_aligned, filename = 'exploration/reference.png',
       width = 20, height = 18, units = 'cm', dpi = 300)

# ggplot(filter(detectedObjects, area < 2500)) +
#   geom_sf(aes(fill = Confidence), col = NA) +
#   scale_fill_viridis_c() +
#   theme_void() +
#   theme(panel.background = element_rect(fill = "black")) 

ggplot(detectedObjectsFiltered) +
  geom_violin(aes(y = as.numeric(area)*0.0001, x = as.factor(pad))) +
  labs(y = "Area (ha)", x = "Padding size", title = "Area of detected objects by padding size")

library(mapview)

mapview(detectedObjectsFiltered, zcol = "Confidence") +
  mapview(train, col.regions = 'red') +
  mapview(test, col.regions = 'orange')

test %>% 
  st_filter(detectedObjectsFiltered, .predicate = st_intersects)

# detectedObjectsFilteredInt = detectedObjectsFiltered %>% 
#   rowwise() %>% 
#   mutate(
#     areaInt = st_intersection(geometry, test$geometry) %>%
#       st_area() %>% sum()
#   )
# 
# save(detectedObjectsFilteredInt, file = "backup_validation_gullies.RData")
load(file = "backup_validation_gullies.RData")
detectedObjectsFilteredInt


detectedObjectsFiltered %>% 
  st_intersects(test)
t = detectedObjectsFilteredInt %>% 
  mutate(intPerc = as.numeric(areaInt)/area*100)

t %>% 
  filter(intPerc > 0, intPerc <= 100) %>% 
  ggplot() +
  geom_point(aes(intPerc, Confidence))
