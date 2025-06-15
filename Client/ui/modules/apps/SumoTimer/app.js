angular.module('beamng.apps')
.directive('sumotimer', ['CanvasShortcuts','$timeout', function (CanvasShortcuts, $timeout) {
    return {
        template: `
            <div id="sumotimerDiv" style="max-height:100%; width:100%; margin:0px; background:transparent;" layout="row" layout-align="center left" layout-wrap>        
                <div id="circleCanvasDiv" style="position:absolute; marginTop:0; marginLeft:0; width:100%; height:100%;">
                    <canvas id="circleCanvas" style="width:100%; height:100%;" width="500" height="500"></canvas>
                </div>
            </div>
        `,
        replace: true,
        restrict: 'EA',
        link: function (scope, element, attrs) {
            var streamsList = ['Sumo'];
            var normalizedValue = 0;
            StreamsManager.add(streamsList);
            scope.$on('$destroy', function () {
                StreamsManager.remove(streamsList);
            });
            
            function ensureCanvas() {
                if (!canvas || !ctx) {
                    canvas = document.getElementById('circleCanvas');
                    ctx = canvas ? canvas.getContext('2d') : null;
                }
            } 

            function syncNormalizedValue(value) {
                normalizedValue = Math.min(Math.max(value, 0), 1); // Clamp between 0–1
                updateSector();
            }

            function removeTimer() {
                ensureCanvas();
                if (ctx) {
                    ctx.clearRect(0, 0, canvas.width, canvas.height);
                }
            }

            function animateCircleSize() {
                const originalWidth = canvas.width;
                const originalHeight = canvas.height;
                const targetWidth = originalWidth * 1.1;
                const targetHeight = originalHeight * 1.1;
                const duration = 500; // Total duration in milliseconds for the animation
                const stepTime = 20; // Time in milliseconds between each step
                let currentStep = 0;
                const totalSteps = duration / stepTime;

                const sizeInterval = setInterval(() => {
                    ensureCanvas();
                    currentStep++;
                    const stepRatio = currentStep / totalSteps;
                    if (currentStep <= totalSteps / 2) {
                        // Increasing size
                        canvas.width = originalWidth + (targetWidth - originalWidth) * stepRatio * 2;
                        canvas.height = originalHeight + (targetHeight - originalHeight) * stepRatio * 2;
                    } else {
                        // Decreasing size
                        canvas.width = targetWidth - (targetWidth - originalWidth) * (stepRatio - 0.5) * 2;
                        canvas.height = targetHeight - (targetHeight - originalHeight) * (stepRatio - 0.5) * 2;
                    }

                    // Redraw the circle and sector after resizing
                    if (currentStep >= totalSteps) {
                        clearInterval(sizeInterval);
                        canvas.width = originalWidth; // Reset to original size to avoid floating point errors
                        canvas.height = originalHeight;
                    }
                    updateSector();
                }, stepTime);
            }

            function updateSector() {
                canvas = document.getElementById('circleCanvas');
                if (!canvas) { 
                    return;
                }
                ctx = canvas.getContext('2d');
                let x = canvas.width / 2;
                let y = canvas.height / 2;
                ctx.clearRect(0, 0, canvas.width, canvas.height); // Clear canvas before drawing

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

                let endAngle = startAngle + (2 * Math.PI * normalizedValue);
                let radius = 200;
                let counterClockwise = false;
                if (normalizedValue > 0.75) {
                    fillColor = 'red';
                } else {
                    fillColor = 'white';
                }
                drawCircle();
                drawSector();

            }
            
            var startAngle = 1.5 * Math.PI;
            var fillColor = 'white';
            var canvas;
            var ctx;

            // Wait for the DOM to be fully loaded
            document.addEventListener('DOMContentLoaded', function() {
            // Wrap canvas initialization inside $timeout to ensure it runs after the DOM is loaded
                canvas = document.getElementById('circleCanvas');
                if (!canvas) {
                    console.error("Canvas element not found.");
                    return;
                }
            });

            scope.$on('VehicleChange', function (event, data) {
            });

            scope.$on('sumoAnimateCircleSize', function (event, data) {
                animateCircleSize();
                console.log("Animating circle size", data);
            });

            scope.$on('sumoRemoveTimer', function (event, data) {
                removeTimer(); //extra for if the time is still ticking
            });

            scope.$on('sumoSyncTimer', function (event, data) {
                syncNormalizedValue(data); // data is the 0-1 value from Lua
            });

        }
    };
}]);


// 
// FIXME: Date.now()       --same format as in lua and in ms
