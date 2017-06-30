@echo on
call :%*
goto :reset_dir

:qt570
cd C:\projects
if exist "Qt5.7.0" goto :reset_dir
curl -kLO https://www.slepin.fr/obs-websocket/ci/qt570.zip -f --retry 5 -C -
7z x qt570.zip -o"Qt5.7.0"
goto :reset_dir

:obs-studio-build
cd C:\projects
if exist "obs-studio" goto :reset_dir
curl -kLO https://obsproject.com/downloads/dependencies2013.zip -f --retry 5 -C -
7z x dependencies2013.zip -odependencies2013
git clone -b %OBS_STUDIO_VERSION% --single-branch --depth 1 --recursive https://github.com/jp9000/obs-studio.git
cd obs-studio
mkdir build build32 build64
cd ./build32 && cmake -G "Visual Studio 12 2013" -DCOPIED_DEPENDENCIES=false -DCOPY_DEPENDENCIES=true ..
cd ../build64 && cmake -G "Visual Studio 12 2013 Win64" -DCOPIED_DEPENDENCIES=false -DCOPY_DEPENDENCIES=true ..
call msbuild /m /p:Configuration=%build_config% C:\projects\obs-studio\build32\obs-studio.sln /logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll" 
call msbuild /m /p:Configuration=%build_config% C:\projects\obs-studio\build64\obs-studio.sln /logger:"C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll" 
goto :reset_dir

:obs-websocket-build
cd C:\projects\obs-websocket
mkdir build32 build64
cd ./build32 && cmake -G "Visual Studio 12 2013" -DQTDIR="%QTDIR32%" -DLibObs_DIR="C:\projects\obs-studio\build32\libobs" -DLIBOBS_INCLUDE_DIR="C:\projects\obs-studio\libobs" -DLIBOBS_LIB="C:\projects\obs-studio\build32\libobs\%build_config%\obs.lib" -DOBS_FRONTEND_LIB="C:\projects\obs-studio\build32\UI\obs-frontend-api\%build_config%\obs-frontend-api.lib" .. 
cd ../build64 && cmake -G "Visual Studio 12 2013 Win64" -DQTDIR="%QTDIR64%" -DLibObs_DIR="C:\projects\obs-studio\build64\libobs" -DLIBOBS_INCLUDE_DIR="C:\projects\obs-studio\libobs" -DLIBOBS_LIB="C:\projects\obs-studio\build64\libobs\%build_config%\obs.lib" -DOBS_FRONTEND_LIB="C:\projects\obs-studio\build64\UI\obs-frontend-api\%build_config%\obs-frontend-api.lib" .. 
goto :reset_dir

:reset_dir
cd C:\projects\obs-websocket

:eof