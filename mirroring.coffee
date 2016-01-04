module.exports = [
	# ┌───┬───┐
	# │ 0 │ 1 │
	# ├───┼───┤
	# │ 2 │ 3 │
	# └───┴───┘
	{name: 'One Page (0)', mirror: [0, 0, 0, 0]}
	{name: 'One Page (1)', mirror: [1, 1, 1, 1]}
	{name: 'One Page (2)', mirror: [2, 2, 2, 2]}
	{name: 'One Page (3)', mirror: [3, 3, 3, 3]}
	{name: 'Horizontal Mirror', mirror: [0, 0, 1, 1]}
	{name: 'Vertical Mirror', mirror: [0, 1, 0, 1]}
	{name: '4-Screen', mirror: [0, 1, 2, 3]}
	{name: 'Diagonal', mirror: [0, 1, 1, 0]}
	{name: 'L-Shaped', mirror: [0, 1, 1, 1]}
	{name: '3-Screen Vertical', mirror: [0, 2, 1, 2]}
	{name: '3-Screen Horizontal', mirror: [0, 1, 2, 2]}
	{name: '3-Screen Diagonal', mirror: [0, 1, 1, 2]}
]

