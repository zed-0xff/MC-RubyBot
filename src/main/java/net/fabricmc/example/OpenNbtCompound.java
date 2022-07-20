package net.fabricmc.example;

import java.util.Map;
import java.util.Arrays;

import net.minecraft.nbt.*;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

public class OpenNbtCompound extends NbtCompound {

    private static final Gson GSON = new Gson();

    private JsonArray convertList(NbtList list) {
        JsonArray arr = new JsonArray();
        if( list.size() == 0 ) {
            return arr;
        }
        NbtElement value0 = list.get(0);
        switch( value0.getType() ){
            case BYTE_TYPE:
                for( NbtElement value : list ) arr.add(((NbtByte)value).byteValue());
                break;
            case COMPOUND_TYPE:
                for( NbtElement value : list ) {
                    OpenNbtCompound tmp = new OpenNbtCompound();
                    tmp.copyFrom((NbtCompound)value);
                    arr.add(tmp.asJson());
                }
                break;
            case DOUBLE_TYPE:
                for( NbtElement value : list ) arr.add(((NbtDouble)value).doubleValue());
                break;
            case FLOAT_TYPE:
                for( NbtElement value : list ) arr.add(((NbtFloat)value).floatValue());
                break;
            case INT_ARRAY_TYPE:
                for( NbtElement value : list ) arr.add(GSON.toJsonTree(((NbtIntArray)value).getIntArray()));
                break;
            case INT_TYPE:
                for( NbtElement value : list ) arr.add(((NbtInt)value).intValue());
                break;
            case LIST_TYPE:
                for( NbtElement value : list ) arr.add(convertList((NbtList)value));
                break;
            case LONG_ARRAY_TYPE:
                for( NbtElement value : list ) arr.add(GSON.toJsonTree(((NbtLongArray)value).getLongArray()));
                break;
            case LONG_TYPE:
                for( NbtElement value : list ) arr.add(((NbtLong)value).longValue());
                break;
            case SHORT_TYPE:
                for( NbtElement value : list ) arr.add(((NbtShort)value).shortValue());
                break;
            default:
                // also covers STRING_TYPE
                for( NbtElement value : list ) arr.add(value.asString());
                break;
        }
        return arr;
    }

    public static JsonObject toJson(NbtCompound src) {
        OpenNbtCompound tmp = new OpenNbtCompound();
        tmp.copyFrom(src);
        return tmp.asJson();
    }

    public JsonObject asJson() {
        JsonObject obj = new JsonObject();
        for (Map.Entry<String, NbtElement> entry : toMap().entrySet()) {
            String key = entry.getKey();
            if ( key.equals("Lore") || key.equals("textures") ) // XXX
                continue;
            NbtElement value = entry.getValue();
            switch( value.getType() ){
//				case BYTE_ARRAY_TYPE:
//					break;
				case BYTE_TYPE:
                    obj.addProperty(key, ((NbtByte)value).byteValue());
					break;
				case COMPOUND_TYPE:
                    OpenNbtCompound tmp = new OpenNbtCompound();
                    tmp.copyFrom((NbtCompound)value);
                    obj.add(key, tmp.asJson());
					break;
				case DOUBLE_TYPE:
                    obj.addProperty(key, ((NbtDouble)value).doubleValue());
					break;
				case FLOAT_TYPE:
                    obj.addProperty(key, ((NbtFloat)value).floatValue());
					break;
				case INT_ARRAY_TYPE:
                    obj.add(key, GSON.toJsonTree(((NbtIntArray)value).getIntArray()));
					break;
				case INT_TYPE:
                    obj.addProperty(key, ((NbtInt)value).intValue());
					break;
				case LIST_TYPE:
                    obj.add(key, convertList((NbtList)value));
					break;
				case LONG_ARRAY_TYPE:
                    obj.add(key, GSON.toJsonTree(((NbtLongArray)value).getLongArray()));
					break;
				case LONG_TYPE:
					obj.addProperty(key, ((NbtLong)value).longValue());
					break;
				case SHORT_TYPE:
					obj.addProperty(key, ((NbtShort)value).shortValue());
					break;
                default:
                    // also covers STRING_TYPE
                    obj.addProperty(key, value.asString());
                    break;
            }
        }
        return obj;
    }
}
