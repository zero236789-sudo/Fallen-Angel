# WaveData.gd
# Pon este archivo en res://Scripts/WaveData.gd
# Es un Resource: cada oleada es un archivo .tres configurable desde el Inspector

class_name WaveData
extends Resource

## Nombre de la oleada (solo para identificarla en el Inspector)
@export var wave_name: String = "Oleada 1"

## Tiempo de espera antes de que empiece esta oleada (en segundos)
@export var delay_before_wave: float = 2.0

## Lista de grupos de enemigos que spawnean en esta oleada
@export var enemy_groups: Array[EnemySpawnGroup] = []

## Si es true, espera a que todos los enemigos mueran antes de pasar a la siguiente
@export var wait_for_clear: bool = true

## Mensaje que aparece en pantalla al iniciar la oleada (deja vacío para no mostrar nada)
@export var wave_message: String = ""
