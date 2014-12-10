object Form4: TForm4
  Left = 0
  Top = 0
  Width = 880
  Height = 640
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSizeToolWin
  Caption = '3D View'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnMouseWheelDown = FormMouseWheelDown
  OnMouseWheelUp = FormMouseWheelUp
  PixelsPerInch = 96
  TextHeight = 13
  object GLSceneViewer1: TGLSceneViewer
    Left = 0
    Top = 0
    Width = 864
    Height = 606
    Camera = GLCamera1
    Buffer.FogEnvironment.FogColor.Color = {0000003F0000003F0000003F0000803F}
    Buffer.FogEnvironment.FogStart = 1.000000000000000000
    Buffer.FogEnvironment.FogEnd = 200.000000000000000000
    Buffer.BackgroundColor = clWindow
    Buffer.FogEnable = True
    Buffer.ShadeModel = smSmooth
    FieldOfView = 161.259384155273400000
    Align = alClient
    OnMouseDown = GLSceneViewer1MouseDown
    OnMouseMove = GLSceneViewer1MouseMove
    OnMouseUp = GLSceneViewer1MouseUp
  end
  object GLScene1: TGLScene
    ObjectsSorting = osRenderFarthestFirst
    Left = 8
    Top = 80
    object GLLightSource1: TGLLightSource
      Ambient.Color = {CDCC4C3ECDCC4C3ECDCC4C3E0000803F}
      ConstAttenuation = 1.000000000000000000
      Diffuse.Color = {DCD8583FDCD8583FC6BF3F3F0000803F}
      Position.Coordinates = {0000A0C1000070C10000C8410000803F}
      SpotCutOff = 180.000000000000000000
      SpotDirection.Coordinates = {00000000000000000000000000000000}
    end
    object GLDummyCube1: TGLDummyCube
      Direction.Coordinates = {0000000000000000FFFF7F3F00000000}
      Up.Coordinates = {00000000FFFF7F3F0000000000000000}
      CubeSize = 5.000000000000000000
      object GLSpaceText1: TGLSpaceText
        Material.FrontProperties.Ambient.Color = {F3F2F23EBFBEBE3E8786863E0000803F}
        Material.FrontProperties.Diffuse.Color = {D7D6D63EABAAAA3EEDEC6C3E0000803F}
        Direction.Coordinates = {00000000000080BF0000000000000000}
        Position.Coordinates = {000000C00000E0C0666666BF0000803F}
        RollAngle = 90.000000000000000000
        Up.Coordinates = {00000000000000000000803F00000000}
        Extrusion = 0.100000001490116100
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Text = 'c'#39't Hacks'
      end
      object GLArrowLineZ: TGLArrowLine
        Material.FrontProperties.Diffuse.Color = {CDCC4C3FCDCC4C3FBBBA3A3F0000803F}
        Material.FrontProperties.Emission.Color = {AFAEAE3E00000000A1A0A03D0000803F}
        Direction.Coordinates = {00000000000000800000803F00000000}
        BottomRadius = 0.100000001490116100
        Height = 4.000000000000000000
        TopRadius = 0.100000001490116100
        TopArrowHeadHeight = 1.000000000000000000
        TopArrowHeadRadius = 0.200000002980232200
        BottomArrowHeadHeight = 0.500000000000000000
        BottomArrowHeadRadius = 0.200000002980232200
        object GLCylinder1: TGLCylinder
          Material.FrontProperties.Ambient.Color = {C9C8483FC9C8483FC9C8483F0000803F}
          Material.FrontProperties.Diffuse.Color = {C9C8483FC9C8483FC9C8483F0000803F}
          Direction.Coordinates = {000000000000803F0000000000000000}
          PitchAngle = 90.000000000000000000
          Position.Coordinates = {00000000000000000000803F0000803F}
          Up.Coordinates = {0000000000000000000080BF00000000}
          Normals = nsFlat
          BottomRadius = 0.200000002980232200
          Height = 2.000000000000000000
          TopRadius = 0.200000002980232200
          object GLCylinder2: TGLCylinder
            Material.FrontProperties.Ambient.Color = {DDDC5C3FDDDC5C3FDDDC5C3F9A99993E}
            Material.FrontProperties.Diffuse.Color = {DDDC5C3FDDDC5C3FDDDC5C3F9A99993E}
            Material.FrontProperties.Emission.Color = {DDDC5C3FDDDC5C3FDDDC5C3F9A99993E}
            Material.BlendingMode = bmTransparency
            Direction.Coordinates = {00000000000000800000803F00000000}
            PitchAngle = 90.000000000000000000
            Position.Coordinates = {0000000000000040000000000000803F}
            Normals = nsFlat
            BottomRadius = 0.200000002980232200
            Height = 2.000000000000000000
            TopRadius = 0.200000002980232200
          end
          object GLAnnulus1: TGLAnnulus
            Material.FrontProperties.Diffuse.Color = {EDEC6C3EFDFC7C3E8382823E0000803F}
            Direction.Coordinates = {00000080000000000000803F00000000}
            Position.Coordinates = {000000000000C0BF000000000000803F}
            Up.Coordinates = {00000000000080BF0000000000000000}
            BottomRadius = 0.400000005960464500
            Height = 1.299999952316284000
            BottomInnerRadius = 0.300000011920929000
            TopInnerRadius = 0.400000005960464500
            TopRadius = 0.500000000000000000
          end
        end
        object GLArrowLineY: TGLArrowLine
          Material.FrontProperties.Diffuse.Color = {CDCC4C3FCDCC4C3FBBBA3A3F0000803F}
          Material.FrontProperties.Emission.Color = {00000000AFAEAE3EB1B0B03D0000803F}
          Direction.Coordinates = {000000800000803FECAD092700000000}
          PitchAngle = 90.000000000000000000
          TurnAngle = 90.000000000000000000
          Up.Coordinates = {0000803F000000000000000000000000}
          BottomRadius = 0.100000001490116100
          Height = 4.000000000000000000
          TopRadius = 0.100000001490116100
          TopArrowHeadHeight = 1.000000000000000000
          TopArrowHeadRadius = 0.200000002980232200
          BottomArrowHeadHeight = 0.500000000000000000
          BottomArrowHeadRadius = 0.200000002980232200
        end
        object GLArrowLineX: TGLArrowLine
          Material.FrontProperties.Diffuse.Color = {CDCC4C3FCDCC4C3FBBBA3A3F0000803F}
          Material.FrontProperties.Emission.Color = {00000000C1C0C03DA3A2A23E0000803F}
          Direction.Coordinates = {0000803F000000002FBD3BB400000000}
          BottomRadius = 0.100000001490116100
          Height = 4.000000000000000000
          TopRadius = 0.100000001490116100
          TopArrowHeadHeight = 1.000000000000000000
          TopArrowHeadRadius = 0.200000002980232200
          BottomArrowHeadHeight = 0.500000000000000000
          BottomArrowHeadRadius = 0.200000002980232200
        end
      end
      object GLExtrusionSolid1: TGLExtrusionSolid
        Material.FrontProperties.Ambient.Color = {9796163F9796163F9796163F0000803F}
        Material.FrontProperties.Diffuse.Color = {9796163F9796163F9796163F0000803F}
        Material.FrontProperties.Shininess = 19
        Material.FaceCulling = fcCull
        Contours = <>
        Parts = [espOutside, espStartPolygon, espStopPolygon]
        Height = 0.500000000000000000
        Stacks = 2
        Normals = nsSmooth
        MinSmoothAngle = 5.000000000000000000
      end
      object GLXYZGrid1: TGLXYZGrid
        Position.Coordinates = {000030C10000C0C00AD7233C0000803F}
        LineColor.Color = {8180003F8180003FC1C0403F0000803F}
        LineWidth = 2.000000000000000000
        XSamplingScale.Max = 22.000000000000000000
        XSamplingScale.Step = 1.000000000000000000
        YSamplingScale.Max = 12.000000000000000000
        YSamplingScale.Step = 1.000000000000000000
        ZSamplingScale.Step = 0.100000001490116100
      end
      object GLCube1: TGLCube
        Material.BackProperties.Emission.Color = {CDCC4C3ECDCC4C3ECDCC4C3E0000803F}
        Material.BackProperties.Specular.Color = {CDCC4C3ECDCC4C3ECDCC4C3E0000803F}
        Material.FrontProperties.Ambient.Color = {F3F2F23EE3E2E23EBFBEBE3E0000803F}
        Material.FrontProperties.Diffuse.Color = {A5A4243FF7F6F63EAFAEAE3E0000803F}
        Material.FaceCulling = fcCull
        Direction.Coordinates = {00000000000000800000803F00000000}
        Position.Coordinates = {0000000000000000000000BF0000803F}
        CubeSize = {0000B041000040410000803F}
      end
      object GLDummyCube2: TGLDummyCube
        Direction.Coordinates = {000000000000803F0000000000000000}
        Position.Coordinates = {0000000000000000000040C00000803F}
        Up.Coordinates = {0000000000000000000080BF00000000}
        CubeSize = 2.000000000000000000
      end
    end
    object GLCamera1: TGLCamera
      DepthOfView = 100.000000000000000000
      FocalLength = 50.000000000000000000
      SceneScale = 2.000000000000000000
      TargetObject = GLDummyCube2
      Position.Coordinates = {000000C1000080C10000A0410000803F}
      Direction.Coordinates = {999919BFCDCC4CBF0000000000000000}
      Up.Coordinates = {00000000000000000000803F00000000}
    end
  end
  object Timer1: TTimer
    Interval = 50
    OnTimer = Timer1Timer
    Left = 8
    Top = 48
  end
end
