angular.module('beamng.apps')
.directive('sumoresetrules', function () {
  return {
    template: `
      <div style="padding: 10px; font-family: sans-serif; color: white; width: 100%;">
        <!-- Reset Status -->
        <div style="text-align: center; margin-bottom: 20px; font-size: 20px;">
          <strong style="color: {{isResetAllowed() ? '#0f0' : '#f00'}};">
            {{isResetAllowed() ? '✔  Reset Available' : '✖  Cannot Reset'}}
          </strong>
        </div>

        <!-- Status Items (excluding Car Repair) -->
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
          <div style="text-align: center;" ng-repeat="item in visibleItems">
            <div style="margin-bottom: 5px;">{{item.description}}</div>
            <img
              ng-src="{{item.image}}"
              alt="{{item.name}}"
              style="width: 100px; height: 100px; opacity: {{item.status === 'ok' ? 1 : 0.4}};"
            >
            <div style="margin-top: 5px;">
              <strong>{{item.name}}</strong><br>
              <span style="color: {{item.status === 'ok' ? '#0f0' : '#f00'}};">
                {{item.status === 'ok' ? '✔' : '✖'}}
              </span>
            </div>
          </div>
        </div>
      </div>
    `,
    restrict: 'EA',
    replace: true,
    link: function (scope) {
      scope.statusItems = [
        {
          name: 'Car Repair',
          image: '', // Hidden
          status: 'ok',
          description: '' // Not shown
        },
        {
          name: 'Speed Limit',
          image: 'speedLimitIcon.png',
          status: 'ok',
          description: 'Must be going under 20 km/h'
        },
        {
          name: 'Outside Safe Zone',
          image: 'safezoneIcon.png',
          status: 'ok',
          description: 'Must be outside a safe zone'
        }
      ];

      // Only visible items (hide Car Repair)
      scope.visibleItems = scope.statusItems.filter(item => item.name !== 'Car Repair');

      // Reset allowed only if Car Repair is ok
      scope.isResetAllowed = function () {
        const carRepair = scope.statusItems.find(item => item.name === 'Car Repair');
        return carRepair && carRepair.status === 'ok';
      };

      scope.$on('sumoSetRuleStatus', function (event, data) {
        data.rule = data.rule || '';
        data.status = data.status || 'ok';
        for (var i = 0; i < scope.statusItems.length; i++) {
          if (scope.statusItems[i].name === data.rule) {
            scope.statusItems[i].status = data.status;
            break;
          }
        }
      });
    }
  };
});
