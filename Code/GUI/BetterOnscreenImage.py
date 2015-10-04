
from panda3d.core import TransparencyAttrib, Vec3, Texture
from direct.gui.OnscreenImage import OnscreenImage

from ..Util.DebugObject import DebugObject
from ..Globals import Globals


class BetterOnscreenImage(DebugObject):

    """ Simple wrapper arround OnscreenImage, providing a simpler interface """

    def __init__(self, image=None, parent=None, x=0, y=0, w=None, h=None,
                 transparent=True, near_filter=True, any_filter=True):
        """ Creates a new image, taking (x,y) as topleft coordinates.

        When near_filter is set to true, a near filter will be set to the
        texture passed. This provides sharper images.

        When any_filter is set to false, the passed image won't be modified at
        all. This enables you to display existing textures, otherwise the
        texture would get a near filter in the 3D View, too. """

        DebugObject.__init__(self, "BetterOnscreenImage")

        if not isinstance(image, Texture):
            if not isinstance(image, str):
                print "Invalid argument to image parameter:", image
                return
            image = Globals.loader.loadTexture(image)

            if w is None or h is None:
                w, h = image.getXSize(), image.getYSize()
        else:
            if w is None or h is None:
                w = 10
                h = 10

        self._w, self._h = w, h
        self._initial_pos = self._translate_pos(x, y)

        self._node = OnscreenImage(
            image=image, parent=parent, pos=self.initialPos,
            scale=(w / 2.0, 1, h / 2.0))

        if transparent:
            self._node.set_transparency(TransparencyAttrib.MAlpha)

        tex = self._node.getTexture()

        if nearFilter and anyFilter:
            tex.setMinfilter(Texture.FTNearest)
            tex.setMagfilter(Texture.FTNearest)

        if anyFilter:
            tex.setAnisotropicDegree(8)
            tex.setWrapU(Texture.WMClamp)
            tex.setWrapV(Texture.WMClamp)

    def getInitialPos(self):
        """ Returns the initial position of the image. This can be used for
        animations """
        return self.initialPos

    def posInterval(self, *args, **kwargs):
        """ Returns a pos interval, this is a wrapper around
        NodePath.posInterval """
        return self._node.posInterval(*args, **kwargs)

    def hprInterval(self, *args, **kwargs):
        """ Returns a hpr interval, this is a wrapper around
        NodePath.hprInterval """
        return self._node.hprInterval(*args, **kwargs)

    def setImage(self, img):
        """ Sets the current image """
        self._node.setImage(img)

    def setPos(self, x, y):
        """ Sets the position """
        self._node.setPos(self.translatePos(x, y))

    def translatePos(self, x, y):
        """ Converts 2d coordinates to pandas coordinate system """
        return Vec3(x + self.w / 2.0, 1, -y - self.h / 2.0)

    def setShader(self, shader):
        self._node.setShader(shader)

    def setShaderInput(self, *args):
        self._node.setShaderInput(*args)

    def remove(self):
        self._node.remove()

    def hide(self):
        self._node.hide()

    def show(self):
        self._node.show()
