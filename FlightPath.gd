extends Line2D

var flight_points = []

func _on_Starship_Position_Change( position_vector ) :
	flight_points.append(position_vector)
	self.points = flight_points
