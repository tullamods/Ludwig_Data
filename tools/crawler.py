# -*- coding: utf-8 -*-
import files, api

files.Store('classes.dat', api.GetClasses('http://static.wowhead.com/js/locale_enus.js?1241'))
files.Store('items.dat', api.GetItems('http://www.wowhead.com/items?filter=cr=151:151;crs=4:1;crv=', range(0, 115001, 50)))