extends Node

signal got_tricked(house_node)
signal got_candy(house_node, candy_amount)
signal in_range()
signal out_range()
signal has_been_knocked(knocked: bool)
signal just_knocked()


## This file is set to auto load meaning it is available in every scene
# used as the central game manager