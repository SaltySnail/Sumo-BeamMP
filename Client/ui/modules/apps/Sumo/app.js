angular.module('beamng.apps')
.directive('sumo', ['CanvasShortcuts', function (CanvasShortcuts) {
	return {
		template: '<div id="sumoApp" style="max-height:100%; width:100%; margin:15px; background:transparent;" layout="row" layout-align="center left" layout-wrap>' +		
					'<div id="circleCanvasDiv" style="position:absolute; marginTop:0; marginLeft:0">' +
						'<canvas id="circleCanvas" width="500" height="500">' +
						'</canvas>' +
					'</div>' + 
				  '</div>',
				
		replace: true,
		restrict: 'EA',
		link: function (scope, element, attrs) {
		var streamsList = ['Sumo'];
		StreamsManager.add(streamsList);
	scope.$on('$destroy', function () {
		StreamsManager.remove(streamsList);
	});

	element.ready(function () {
		const canvas = document.getElementById('circleCanvas');
		const ctx = canvas.getContext('2d');
		let radius = 200;
		let startAngle = 1.5 * Math.PI;
		let endAngle = 1.5000001 * Math.PI;
		let counterClockwise = false;
		let x = canvas.width / 2;
		let y = canvas.height / 2;
		let fillColor = 'white';
		let time = 0;
		let endTime = 30;


		function drawCircle() {
			ctx.beginPath();
			ctx.arc(x, y, radius, 0, 2 * Math.PI, counterClockwise);
			ctx.fillStyle = 'black';
			ctx.fill();
		}

		function drawSector() {
			ctx.beginPath();
			ctx.moveTo(x, y);
			ctx.arc(x, y, radius + 1, startAngle, endAngle, counterClockwise);
			ctx.lineTo(x, y);
			ctx.fillStyle = fillColor;
			ctx.fill();
		}

		function updateSector() {
			endAngle = startAngle + (2 * Math.PI * (time/endTime));
			drawCircle();
			drawSector();
			if (endAngle > startAngle + 1.5 * Math.PI) {
				fillColor = 'red';
			}
			if (endAngle > startAngle && endAngle < startAngle + 2 * Math.PI) {
				requestAnimationFrame(updateTime);
			}
		}

		function updateTime() {
			time += 1/144;
			updateSector();
		}
	});
	
	scope.$on('VehicleChange', function (event, data) {
	});

	scope.$on('app:resized', function (event, data) {
		// c.width = data.width;
		// c.height = data.height;
	});
	}
  };
}]);