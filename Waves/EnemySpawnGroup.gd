# EnemySpawnGroup.gd
# Pon este archivo en res://Scripts/EnemySpawnGroup.gd
# Define un grupo de enemigos dentro de una oleada

class_name EnemySpawnGroup
extends Resource

## La escena del enemigo a spawnear (arrastra el .tscn desde el FileSystem)
@export var enemy_scene: PackedScene

## Cuántos enemigos de este tipo spawnean
@export var count: int = 3

## Tiempo entre cada spawn dentro del grupo (en segundos)
@export var spawn_interval: float = 0.5

## Posición X mínima y máxima dentro del área de juego
@export var spawn_x_min: float = 330.0
@export var spawn_x_max: float = 630.0

## Posición Y donde aparecen (por defecto arriba de la pantalla)
@export var spawn_y: float = -50.0

## Si es true, las posiciones X son aleatorias dentro del rango
## Si es false, se distribuyen uniformemente
@export var random_x: bool = true

## Retardo adicional antes de que este grupo empiece a spawnear
## (útil para escalonar varios grupos en la misma oleada)
@export var group_delay: float = 0.0
