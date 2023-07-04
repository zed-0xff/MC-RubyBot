// originally from tweakeroo
package net.fabricmc.example.utils;

import net.fabricmc.example.ExampleMod;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.ConcurrentModificationException;
//import javax.annotation.Nonnull;
import net.minecraft.entity.Entity;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.EntityHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.RaycastContext;
import net.minecraft.world.World;
import net.minecraft.client.MinecraftClient;

public class RayTraceUtils
{
    public static final int USE_LIQUIDS   = 1;
    public static final int USE_ENTITIES  = 2;
    public static final int SHAPE_OUTLINE = 0x10;
    public static final int SHAPE_VISUAL  = 0x20;

    public static final int DEFAULT_FLAGS = 0;

    public static HitResult crosshairTargetOrRaytrace(MinecraftClient mc) {
        return (mc.player == mc.cameraEntity) ? mc.crosshairTarget : getRayTraceFromPlayer(mc);
    }

    public static HitResult getRayTraceFromPlayer(MinecraftClient mc) {
        return getRayTraceFromPlayer(mc, 0);
    }

    public static HitResult getRayTraceFromPlayer(MinecraftClient mc, double distance) {
        return getRayTraceFromPlayer(mc, distance, DEFAULT_FLAGS);
    }

    public static HitResult getRayTraceFromPlayer(MinecraftClient mc, double distance, int flags) {
        if ( mc == null || mc.world == null || mc.player == null )
            return null;

        if ( distance == 0 ) {
            distance = mc.interactionManager.getReachDistance();
        }

        return RayTraceUtils.getRayTraceFromEntity(mc.world, mc.player, flags, distance);
    }

    //@Nonnull
    public static HitResult getRayTraceFromEntity(World worldIn, Entity entityIn, int flags)
    {
        double reach = 5.0d;
        return getRayTraceFromEntity(worldIn, entityIn, flags, reach);
    }

    // this method is for workarounding ConcurrentModificationException
    private static List<Entity> getOtherEntities(World worldIn, Entity entityIn, net.minecraft.util.math.Box bb) {
        if ( ExampleMod.inRenderThread() ) {
            return worldIn.getOtherEntities(entityIn, bb);
        } else {
            for(int i=0; i<10; i++) {
                try { return worldIn.getOtherEntities(entityIn, bb); } catch (ConcurrentModificationException e) {}
                try { Thread.sleep(10); } catch (InterruptedException e) {} // OK
            }
            return new ArrayList<Entity>();
        }
    }

    //@Nonnull
    public static HitResult getRayTraceFromEntity(World worldIn, Entity entityIn, int flags, double range)
    {
        Vec3d eyesVec = new Vec3d(entityIn.getX(), entityIn.getY() + entityIn.getStandingEyeHeight(), entityIn.getZ());
        Vec3d rangedLookRot = entityIn.getRotationVec(1f).multiply(range);
        Vec3d lookVec = eyesVec.add(rangedLookRot);

        RaycastContext.FluidHandling fluidMode =((flags & USE_LIQUIDS) == USE_LIQUIDS) ?
            RaycastContext.FluidHandling.SOURCE_ONLY :
            RaycastContext.FluidHandling.NONE;
        RaycastContext.ShapeType shape;
        if ( (flags & SHAPE_OUTLINE) == SHAPE_OUTLINE )
            shape = RaycastContext.ShapeType.OUTLINE;
        else if ( (flags & SHAPE_VISUAL) == SHAPE_VISUAL )
            shape = RaycastContext.ShapeType.VISUAL;
        else
            shape = RaycastContext.ShapeType.COLLIDER;

        RaycastContext context = new RaycastContext(eyesVec, lookVec, shape, fluidMode, entityIn);
        HitResult result = worldIn.raycast(context);

        if (result == null) {
            result = BlockHitResult.createMissed(Vec3d.ZERO, Direction.UP, BlockPos.ORIGIN);
        }

        net.minecraft.util.math.Box bb = entityIn.getBoundingBox().expand(rangedLookRot.x, rangedLookRot.y, rangedLookRot.z).expand(1d, 1d, 1d);
        List<Entity> list = ((flags & USE_ENTITIES) == USE_ENTITIES) ?
            getOtherEntities(worldIn, entityIn, bb) :
            new ArrayList<Entity>();

        double closest = result.getType() == HitResult.Type.BLOCK ? eyesVec.distanceTo(result.getPos()) : Double.MAX_VALUE;
        Optional<Vec3d> entityTrace = Optional.empty();
        Entity targetEntity = null;

        for (int i = 0; i < list.size(); i++)
        {
            Entity entity = list.get(i);
            bb = entity.getBoundingBox();
            Optional<Vec3d> traceTmp = bb.raycast(lookVec, eyesVec);

            if (traceTmp.isPresent())
            {
                double distance = eyesVec.distanceTo(traceTmp.get());

                if (distance <= closest)
                {
                    targetEntity = entity;
                    entityTrace = traceTmp;
                    closest = distance;
                }
            }
        }

        if (targetEntity != null)
        {
            result = new EntityHitResult(targetEntity, entityTrace.get());
        }

        return result;
    }
}
