# -*- coding: utf-8 -*-
import files, api

files.Store('items.dat', api.GetItems('http://www.wowhead.com/items?filter=cr=151:151;crs=1:4;crv=', 0, 200000, 1000))
#files.Store('classes.dat', api.GetClasses("http://www.wowhead.com/items={0}|.{0}|?filter=sl={0}", -16, 17))