
''
'' TPixmap
'' for monkey
''
Import minib3d
Import minib3d.monkeyutility
Import mojo.data
'Import minib3d.monkeybuffer



Interface IPixmapManager

	Method LoadPixmap:TPixmap(f$)
	Method CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
	
End

Interface IPreloadManager
		
	Method AllocatePreLoad:Void(size:Int)
	Method PreLoadData:Void(f$, file_id:Int)
	Method SetPixmapFromID:Void(pixmap:TPixmap, file_id:Int, file:String)
	Method SetPreloader:Void(preloader_class:TPixmapPreloader)
	Method IsLoaded:Bool(file_id:Int)
	'Method IsLoaded:Bool(file$) ''this is implemented in base class
	Method Update:Void()
	
End
	

Class TPixmap
	
	Global manager:IPixmapManager ''Use this to Load & Create pixmaps, this is set by render driver
	Global preloader:TPixmapPreloader 
	
	Field width:Int, height:Int
	Field bind:Int =0
	

	'' PreLoadPixmap(file$[])
	'' -- returns 1 for finished load from given array, 0 for Unloaded
	'' -- GetNumberLoaded() contains number of files loaded
	Function PreLoadPixmap:Int(file$[])
		Return preloader.PreLoad(file)
	End
	
	Function GetNumberLoaded:Int()
		Return preloader.GetNumberLoaded()
	End
	
	Function IsLoaded:Bool( p$ )
		Return preloader.IsLoaded( p )
	End

	
	Function LoadPixmap:TPixmap(f$)
		f=FixDataPath(f)
		Return manager.LoadPixmap(f)
	End

	
	Function CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
		Return manager.CreatePixmap(w,h,format)
	End
	
	
	Method ResizePixmap:TPixmap(neww:Int, newh:Int) Abstract
	''averages pixels

	
	Method ResizePixmapNoSmooth:TPixmap(neww:Int, newh:Int) Abstract
	''no average, straight pixels better for fonts, details
	''pixelation ok


	
	Method MaskPixmap:Void(r:Int, g:Int, b:Int)
	
	End
	
	Method ApplyAlpha:Void( pixmap:TPixmap )

	End
	
	Method GetPixel:Int( x:Int, y:Int)
		Return 0
	End
	
	Method SetPixel:Void(x:Int, y:Int, r:Int, g:Int, b:Int, a:Int=255)
	End

	''bind for hardware binding, to avoid duplicating binds for same image
	Method SetBind:Void()
		bind=1
	End
	
	Method ClearBind:Void()
		bind=0
	end
End





Class TPixmapPreloader
	
	Field manager:IPreloadManager
	
	Field loading:Bool = False, loaded:Int = 0, total:Int =0
	
	Field old_file:String[1] ''use only for checking
	Field new_file:String[1] ''proper monkey filenames
	
	Field cur_file:Int=0
	'Field imagebuffer:IPixmapBuffer[]
	
	Method New(m:IPreloadManager)
		manager = m
		manager.SetPreloader(Self)
	End
	
	Method IsLoaded:Bool(f$)
		
		Local id:Int = GetID(f)
		If id=0 Then Return False
		
		Return manager.IsLoaded(id)
	end
	
	Method CheckAllLoaded:int()
		
		If loaded = total Then loading = False; Return 1
		Return 0
	End
	
	
	Method GetNumberLoaded:Int()
		Return loaded
	End
	
	
	Method IncLoader:Void()
		loaded += 1
		CheckAllLoaded()
	End

	'' returns 1 when finished
	Method PreLoad:Int(file$[])
		
		If Not manager Then Error "**ERROR: no preload manager"
		
		''use for async events
		manager.Update()
		
		
		'' what if our queue is replaced by another??
		
'Print "loading "+Int(loading)+" "+old_file[0]+"="+file[0]
			
		If file[0] <> old_file[0]
			'' check to see if its a new list
			
			''...ugh.....mojo compatibilty insists on this
			Local i:Int=0
			new_file = New String[file.Length]
			
			For Local ff$ = Eachin file
				new_file[i] = FixDataPath(ff)
				i+=1
			Next
			
			loaded = 0
			cur_file = 0
			loading = True
			total = file.Length()
			manager.AllocatePreLoad(total) 'New IBuffer[total]
			
			old_file = file
		
		'Elseif file.Length < old_file.Length
			
			'' check for appended list TODO??
		
		Elseif ((Not loading) And (file[0] = old_file[0]))
			Return 1
		Endif
		
		If cur_file >= total Then Return 0
		If loading Then cur_file +=1	

'Print "curfile "+file[cur_file-1]		

		'imagebuffer[cur_file] = New TImageBuffer(Self)

		manager.PreLoadData(new_file[cur_file-1], cur_file )

		
		Return 0
	
	End
	
	Method GetPixmapPreLoad:Void(p:TPixmap, file$)
		
		Local id:Int = GetID(file)
		manager.SetPixmapFromID(p, id, file)
	
	End
	
	
	Method GetID:Int(file$)
		
		If loaded = 0
	
			Return 0
					
		Else

			For Local i:Int=0 To total-1
				
				If file = old_file[i] Or file = new_file[i] Then Return (i+1)
			Next
			
		Endif
		
		Return 0
		
	End

	
End

    