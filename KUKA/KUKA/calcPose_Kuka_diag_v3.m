function [position, orientation, midpoints_pos, midpoints_ori, velocity_tang] = calcPose_Kuka_diag_v3( ...
    initial_pose, pitch, roll, yaw, radius,ang_velocity)
% for calculating pose in 3D for rotations along a curve.  
% pitch roll and yaw in local end-effector frame.
% Inputs:
% initial_pose:     4x4 homogenous matrix, 
%                   zyx euler angle order, 
%                   position (mm), 
%                   The position of the center of rotation in neutral
%                   orientation (aligned with neck vertical)

% Outputs:
% position:         end effector in global frame, in mm (relative to base of KUKA)
% orientation:      in global frame, in degrees (ZYX)
% velocity_tang:    tangential velocity in mm/s. Assigned to the midpoints
% midpoints:        position and orientation (ZYX)
% yaw:              Will be a single value in degrees corresponding to the 
%                   desired offset/rotation around z-axis (between AP/ML)
%
% Calculates the trajectory on a diagonal, rather than keeping trajectory
% straight, and changing orientation relative to straight.
    
    % pitch_changes are relative to starting neck orientation, not prior move

% positions should be correct locations. Delete the orientation, and place
% the starting orientation as facing AP for me, this is [0,5,-180] ZYX --
% this makes the math easier for adding the 45 degree offset at the end to
% get the orientation you want, while translating in the plane you want.
    

% -------------------------------------------------------%
% when initial pose z-axis offset is positive (global), we need negative 
% initial rotation to bring it in AP direction, then pitch, then drop down,
% then positive to counter offset
% when initial z axis offset is negative, we need positive.

% ensures the initial yaw rot counters initial offset from RoboDK, so that
% traj can apply in AP plane, then transpose it to return the offset. 

initial_eul = rotm2eul_c(initial_pose(1:3,1:3));

initial_z = initial_eul(3);

if (initial_z > 0 && yaw > 0) || (initial_z < 0 && yaw < 0)
    yaw = flip(yaw);
end


    N = numel(pitch);

    %Confirming Variables are column vectors, transpose if not.
    data_sets = {pitch, roll, yaw, radius, ang_velocity};    
    for i = 1:numel(data_sets)
        x = data_sets{i};
        if size(x,1) == 1 && size(x, 2) == 1
            continue
        elseif size(x, 1) == 1 && size(x, 2) > 1  % Check if x is a row vector (1, n)
          data_sets{i} = x';  % Transpose and store back in data_sets
        end
    end
    % Assign transposed variables back to output
    pitch = data_sets{1};
    roll = data_sets{2};
    yaw = data_sets{3};
    fprintf('yaw = %f\n', yaw)
    radius = data_sets{4};
    ang_velocity = data_sets{5};
    
    %Find the axis we are rotating around, asign the amount for zeros.
    if numel(pitch)>1
        N = numel(pitch);
        disp('axis of rotation: pitch')
    elseif numel(yaw)>1
        N = numel(pitch);
        disp('axis of rotation: yaw')
    elseif numel(roll)>1
        N = numel(roll);
        disp('axis of rotation: roll')
    end
    
    %-----------%
    if pitch == 0
        pitch_changes = zeros(N,1);
    else
        pitch_changes = pitch;
    end
    if yaw == 0
        yaw_changes = zeros(N,1);
    else
        yaw_changes = yaw;
    end
    if roll == 0
        roll_changes = zeros(N,1);
    else
        roll_changes = roll;
    end
    fprintf('yaw_changes = %f\n', yaw_changes)

    % Move 1 Homogenous matrix -- Neck Center point from RoboDK and
    % Measurements
    H1 = initial_pose;
    
    % Move 2 (relative to first frame)
    % Preallocate arrays:
    yaw1 = zeros(N,1); %for move 1, when we are facing AP, then apply rotations
    yaw2   = zeros(N,1);
    roll2  = zeros(N,1);
    pitch2 = zeros(N,1);

    % Loop through arrays for pitch (add yaw and roll arrays if needed)
    for i = 1:N
        if numel(yaw_changes)>1
            yaw2(i,1) = deg2rad(yaw_changes(i,1)); %accounts for if yaw is matrix of zeros vs a single rot around z
        else
            yaw2(i,1) = deg2rad(yaw_changes);
        end
        pitch2(i,1) = deg2rad(pitch_changes(i,1));
        roll2(i,1) = deg2rad(roll_changes(i,1));
    end

    midpoints = zeros(N-1,1);
    velocity_tang = zeros(N-1,1);

    % Midpoints
    % Mean of two points, to get midpoint of angular change
    
    % Find the midpoint between initial_pose, and first end movement
    % initial_pose_pitch = rotm2eul_c(initial_pose(1:3,1:3),'ZYX');
    % midpoint1 = (initial_pose_pitch(2,1)+pitch_changes(1,1))/2;
    % % midpoint for going from first point, onwards
    % for i = 1:numel(pitch_changes)-1
    %     midpoints_2_to_end(i,1) = mean(pitch_changes(i:i+1));
    %     velocity_tang(i,1) = radius*mean(ang_velocity(i:i+1));
    % end
    % 
    % % vertcat to have all midpoints together
    % pitch_mid_changes = [midpoint1;midpoints_2_to_end];

    % midpoint for going from first point, onwards
    for i = 1:numel(roll_changes)-1
        midpoints(i,1) = mean(roll_changes(i:i+1));
        velocity_tang(i,1) = abs((radius*mean(ang_velocity(i:i+1)))/1000);
        % cant accept negative speeds** needed this added later.
        % also needed to downsample position values to 1/20 because it was
        % too small
    end

    % vertcat to have all midpoints together
    roll_mid_changes = midpoints;
    
    % Subsequent translations in local frame (the offset from neck)
    t0 = [0; 0; 0];
    t3 = [0; 0; radius];
    
    
    % ----------------------------
    
    % Build ZYX rotation matrices for move1
    Rz = @(yaw)   [cos(yaw)  -sin(yaw)  0;
                   sin(yaw)  cos(yaw)   0;
                   0         0          1];
    Ry = @(pitch) [cos(pitch)   0    sin(pitch);
                   0            1    0;
                   -sin(pitch)  0    cos(pitch)];
    Rx = @(roll)  [1     0           0;
                   0     cos(roll)   -sin(roll);
                   0     sin(roll)   cos(roll)];
    
    % Correct initial 45 degree offset in initial pose, so that we can
    % rotate in AP plane, then Rz_cr will counter rotate back to initial
    % offset of -45 degrees. Yaw is *-1 as z axis local is flipped to point
    % down
    % Rz_cr1 = [cos(-1*yaw2(1))   -sin(-1*yaw2(1))   0;
    %          sin(-1*yaw2(1))     cos(-1*yaw2(1))   0;
    %          0                   0                 1];
    % Ry_cr1 = [1           0           0;
    %          0           1           0;
    %          0           0           1];
    % Rx_cr1 = [1           0           0;
    %          0           1           0;
    %          0           0           1];
    % R_cr1 = Rx_cr1 * Ry_cr1 * Rz_cr1;

    % Build ZYX rotation matrices for counter rotation around z
    Rz_cr = [cos(yaw2(1))  -sin(yaw2(1))   0;
             sin(yaw2(1))   cos(yaw2(1))   0;
             0           0           1];
    Ry_cr = [1           0           0;
             0           1           0;
             0           0           1];
    Rx_cr = [1           0           0;
             0           1           0;
             0           0           1];
   
    % R_cr = transpose(Rx_cr * Ry_cr * Rz_cr); %this reverses 45 deg. we
    % want to keep the 45 deg
    R_cr = Rx_cr * (Ry_cr * Rz_cr);   % Matlab mtimes is left to right??
    
    % R2 = zeros(3,3);
    H2 = zeros(4,4,N);
    H_global = zeros(4,4,N);
    
    % Hcr1 = [R_cr1, t0; 0 0 0 1];
    H4 = [R_cr t0; 0 0 0 1];
    
    for i = 1:N
        % R2 = Rz(yaw2(i)) * Ry(pitch2(i)) * Rx(roll2(i));  % rotation matrix for individual movement
        R2 = Rx(roll2(i)) * (Ry(pitch2(i)) * Rz(yaw1(i))); %no yaw yet (hense yaw1, not yaw2)
        H2(:,:,i) = [R2 t0; 0 0 0 1];                     % H2: rotate to second orientation (no translation), assign to homogenous matrix (local frame)
        H3 = [eye(3) t3; 0 0 0 1];                        % H3: translate along local Z'' of rotated frame (becomes local frame 2)
        
        H_global(:,:,i) = H1 * (H2(:,:,i) * (H3 * H4));            % multiply (from right to left) local transpose with original orientation/position transpose (neck location) -- transpose from local to global frame
    end
    fprintf('H2(:,:,1) = %f\n', H2(:,:,1));
    % Midpoints for Circ Path ------------------------------ %

    for i = 1:N-1
        roll_midpoint(i,1) = deg2rad(roll_mid_changes(i,1));
    end
    
    for i = 1:N-1
        % R2 = Rz(yaw2(i)) * Ry(pitch2(i)) * Rx(roll2(i));  % rotation matrix for individual movement
        R2_mid = Rx(roll_midpoint(i)) * Ry(pitch2(i)) * Rz(yaw2(i));
        H2_mid(:,:,i) = [R2_mid t0; 0 0 0 1];                     % H2: rotate to second orientation (no translation), assign to homogenous matrix (local frame)
        H3_mid = [eye(3) t3; 0 0 0 1];                        % H3: translate along local Z'' of rotated frame (becomes local frame 2)
        H_global_mid(:,:,i) = H1 * H2_mid(:,:,i) * H3_mid * H4;            % multiply (from right to left) local transpose with original orientation/position transpose (neck location) -- transpose from local to global frame
    end



    %--------------------------------

    % Preallocate
    orientation = zeros(N,3);   % ZYX Euler angles (yaw-pitch-roll)
    position = zeros(N,3);   % position vectors
    
    for k = 1:N
        R = H_global(1:3,1:3,k);      % Extract rotation matrix
        p = H_global(1:3,4,k);        % Extract position vector
    
        % Convert rotation matrix to ZYX Euler angles (yaw-pitch-roll)
        % MATLAB uses intrinsic rotations by default
        orientation(k,:) = rad2deg(rotm2eul_c(R, 'ZYX'));  
    
        % Store position
        position(k,:) = p';
    end

    midpoints_ori = zeros(N-1,3);   % ZYX Euler angles (yaw-pitch-roll)
    midpoints_pos = zeros(N-1,3);   % position vectors

    for k = 1:N-1
        R = H_global_mid(1:3,1:3,k);      % Extract rotation matrix
        p = H_global_mid(1:3,4,k);        % Extract position vector
    
        % Convert rotation matrix to ZYX Euler angles (yaw-pitch-roll)
        % MATLAB uses intrinsic rotations by default
        midpoints_ori(k,:) = rad2deg(rotm2eul_c(R, 'ZYX'));  
    
        % Store position
        midpoints_pos(k,:) = p';
    end
        
end


%% --------------------------------- %%

% Nested function for converting rotation matrix to euler angles

%-----------------------------------%
%%

function eul = rotm2eul_c(rotm, sequence)
    if ( (size(rotm,1) ~= 3) || (size(rotm,2) ~= 3) )
        error('rotm2eul: incompatable size');
    end

    if ~exist('sequence', 'var')
        % use the default axis sequence ...
        sequence = 'ZYX';
    end
    eul = zeros(3,1);

    %% Compute the Euler angles theta for the x, y and z-axis from a rotation matrix R, in
    %  dependency of the specified axis rotation sequence for the rotation factorization:
    % For further details see:
    %   [1] Geometric Tools Engine, Documentation: <http://www.geometrictools.com/Documentation/EulerAngles.pdf>, pp. 9-10, 16-17.
    %   [2] Computing Euler angles from a rotation matrix, Gregory G. Slabaugh, <http://www.staff.city.ac.uk/~sbbh653/publications/euler.pdf>
    %   [3] Modelling and Control of Robot Manipulators, L. Sciavicco & B. Siciliano, 2nd Edition, Springer, 2008,
    %       pp. 30-33, formulas (2.19), (2.19'), (2.21) and (2.21').
    switch sequence
        case 'ZYX'
            % convention used by (*) and (**).
            % note: the final orientation is the same as in XYZ order about fixed axes ...
            if (rotm(3,1) < 1)
                if (rotm(3,1) > -1) % case 1: if r31 ~= ±1
                    % Solution with positive sign. It limits the range of the values
                    % of theta_y to (-pi/2, pi/2):
                    eul(1,1) = atan2(rotm(2,1), rotm(1,1)); % theta_z
                    eul(2,1) = asin(-rotm(3,1));            % theta_y
                    eul(3,1) = atan2(rotm(3,2), rotm(3,3)); % theta_x
                else % case 2: if r31 = -1
                    % theta_x and theta_z are linked --> Gimbal lock:
                    % There are infinity number of solutions for theta_x - theta_z = atan2(-r23, r22).
                    % To find a solution, set theta_x = 0 by convention.
                    eul(1,1) = -atan2(-rotm(2,3), rotm(2,2));
                    eul(2,1) = pi/2;
                    eul(3,1) = 0;
                end
            else % case 3: if r31 = 1
                % Gimbal lock: There is not a unique solution for
                %   theta_x + theta_z = atan2(-r23, r22), by convention, set theta_x = 0.
                eul(1,1) = atan2(-rotm(2,3), rotm(2,2));
                eul(2,1) = -pi/2;
                eul(3,1) = 0;
            end
        case 'ZYZ'
            % convention used by (*)
            if (rotm(3,3) < 1)
                if (rotm(3,3) > -1)
                    % Solution with positive sign, i.e. theta_y is in the range (0, pi):
                    eul(1,1) = atan2(rotm(2,3),  rotm(1,3)); % theta_z1
                    eul(2,1) = acos(rotm(3,3));              % theta_y (is equivalent to atan2(sqrt(r13^2 + r23^2), r33) )
                    eul(3,1) = atan2(rotm(3,2), -rotm(3,1)); % theta_z2
                else % if r33 = -1:
                    % Gimbal lock: infinity number of solutions for
                    %   theta_z2 - theta_z1 = atan2(r21, r22), --> set theta_z2 = 0.
                    eul(1,1) = -atan2(rotm(2,1), rotm(2,2)); % theta_z1
                    eul(2,1) = pi;                           % theta_y
                    eul(3,1) = 0;                            % theta_z2
                end
            else % if r33 = 1:
                % Gimbal lock: infinity number of solutions for
                %    theta_z2 + theta_z1 = atan2(r21, r22), --> set theta_z2 = 0.
                eul(1,1) = atan2(rotm(2,1), rotm(2,2)); % theta_z1
                eul(2,1) = 0;                           % theta_y
                eul(3,1) = 0;                           % theta_z2
            end
        % case 'ZYZ-'
        %     % convention used by (**)
        %     if (rotm(3,3) < 1)
        %         if (rotm(3,3) > -1)
        %             % Variant with negative sign. This is a derived solution
        %             % which produces the same effects as the solution above.
        %             % It limits the values of theta_y in the range of (-pi,0):
        %             eul(1,1) = atan2(-rotm(2,3), -rotm(1,3)); % theta_z1
        %             eul(2,1) = -acos(rotm(3,3));              % theta_y (is equivalent to atan2(-sqrt(r13^2 + r23^2), r33) )
        %             eul(3,1) = atan2(-rotm(3,2),  rotm(3,1)); % theta_z2
        %         else % if r33 = -1:
        %             % Gimbal lock: infinity number of solutions for
        %             %   theta_z2 - theta_z1 = atan2(-r12, -r11), --> set theta_z2 = 0.
        %             eul(1,1) = -atan2(-rotm(1,2), -rotm(1,1)); % theta_z1  (correct ???)
        %             eul(2,1) = -pi;                            % theta_y
        %             eul(3,1) = 0;                              % theta_z2
        %         end
        %     else % if r33 = 1:
        %         % Gimbal lock: infinity number of solutions for
        %         %    theta_z2 + theta_z1 = atan2(-r12, -r11), --> set theta_z2 = 0.
        %         eul(1,1) = atan2(-rotm(1,2), -rotm(1,1)); % theta_z1  (correct ???)
        %         eul(2,1) = 0;                             % theta_y
        %         eul(3,1) = 0;                             % theta_z2
        %     end
        otherwise
            error('rotm2eul: %s', WBM.wbmErrorMsg.UNKNOWN_AXIS_SEQ);
    end
end

% (*)  ... The Geometric Tools Engine (http://www.geometrictools.com),
% (**) ... The Robotics System Toolbox for Matlab (http://mathworks.com/help/robotics/index.html).